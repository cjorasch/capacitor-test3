## Issues

Arguments
- call.args vs. call.options?
- call.hasOption("myarg") -> Bool
- call.getBool and call.getInt should not require defaultValue to be specified
- default value as ?? vs arg so not nil? Nil-Coalescing Operator
- getDouble, getFloat.  self.quality = call.get("quality", Float.self, 100)!
- type conversion error vs null value

Return values
- how to return null property value
- how to return other data types (string, array, etc.).  Examples use call.success({value: x})
- how to return null result
- success/error => resolve/reject?
- wrap call in try / catch for standard error handling