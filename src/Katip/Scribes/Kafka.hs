module Katip.Scribes.Kafka where

import Control.Exception
import Control.Monad
import Data.Aeson
import Data.ByteString.Lazy
import Kafka.Producer
import Katip

-- | Created scribe uses hw-kafka-client library, which is binding
-- over librdkafka which in turn implements buffering. Beware to close
-- this scribe properly
kafkaScribe
  :: (Value -> ProducerRecord)
  -- ^ Kafka record creator
  -> ProducerProperties
  -- ^ Producer properties to create Kafka producer
  -> Severity
  -> Verbosity
  -> IO (Either KafkaError Scribe)
kafkaScribe itemToRecord pp sev verb = newProducer pp >>= \case
  Left e         -> return $ Left e
  Right producer -> do
    let
      push item = when (permitItem sev item) $ do
        let
          obj    = itemJson verb item
          record = itemToRecord obj
        produceMessage producer record >>= \case
          Nothing  -> return ()
          Just err -> throwIO err
      fin = do
        flushProducer producer
        closeProducer producer
    return $ Right $ Scribe
      { liPush          = push
      , scribeFinalizer = fin
      }

-- | Kafka record creator function. The key of resulting record is
-- 'Nothing' by default, you can override it if needed
simpleRecord :: TopicName -> ProducePartition -> Value -> ProducerRecord
simpleRecord topic part val = ProducerRecord
  { prTopic     = topic
  , prPartition = part
  , prKey       = Nothing
  , prValue     = Just $ toStrict $ encode val }
