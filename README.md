# How to use

``` haskell
let
  toRecord = simpleRecord "myapp.logs" UnassignedPartition
  props = brokersList [ BrokerAddress "kafka" ] <> compression Lz4
kafka <- kafkaScribe toRecord props DebugS V3 >>= either throwIO return
env <- initLogEnv "myapp" (Environment "devel") >>=
  registerScribe "kafka" kafka defaultScribeSettings
finally (runMyApp env) $ closeScribes env
```
