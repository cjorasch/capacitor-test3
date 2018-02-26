import Foundation
import Capacitor

typealias JSObject = [String:Any]
typealias JSArray = [JSObject]

@objc(Testing)
public class Testing: CAPPlugin {

    struct RuntimeError: Error {
        let message: String
        
        init(_ message: String) {
            self.message = message
        }
        
        public var localizedDescription: String {
            return message
        }
    }
    
    // Test incoming arguments and outgoing results
    @objc func callTesting(_ call: CAPPluginCall) {
        // throw RuntimeError("My Error")
        // print("options", call.options)
        print("str1", call.getString("str1") as Any) // "" => ""
        print("str2", call.getString("str2") as Any) // "abc" => "abc"
        print("str3", call.getString("str3") as Any) // null => nil
        print("str4", call.getString("str4") as Any) // undefined => nil
        print("str5", call.getString("str5") as Any) // unspecified => nil
        // or dictionary.index(forKey: "someKey") == nil
        print("str1 specified", call.options.index(forKey: "str1") != nil) // "" => true
        print("str3 specified", call.options.index(forKey: "str3") != nil) // null => true
        print("str4 specified", call.options.index(forKey: "str4") != nil) // undefined => false
        print("str5 specified", call.options.index(forKey: "str5") != nil) // unspecified => false
        print("str2bool", call.getBool("str2", defaultValue: nil) as Any) // "abc" => nil
        print("str2int", call.getInt("str2", defaultValue: nil) as Any) // "abc" => nil
        print("bool1", call.getBool("bool1", defaultValue: nil) as Any) // false => false
        print("bool2", call.getBool("bool2", defaultValue: nil) as Any) // true => true
        print("num1", call.getInt("num1", defaultValue: nil) as Any) // 0 => 0
        print("num2", call.getInt("num2", defaultValue: nil) as Any) // 123 => 123
        print("num3", call.getInt("num3", defaultValue: nil) as Any) // 123.456 => nil
        print("num3float", call.get("num3", Float.self) as Any) // 123.456 => 123.456001
        print("num3double", call.get("num3", Double.self) as Any) // 123.456 => 123.456
        print("num2str", call.getString("num2") as Any) // 123 => nil
        print("num2bool", call.getBool("num2", defaultValue: nil) as Any) // 123 => nil
        
        // print("arr1", call.getArray("arr1", [Int:Any].self) as Any)
        print("arr1", call.getArray("arr1", Int.self) as Any)
        print("arr1any", call.getArray("arr1", Any.self) as Any)
        // print("arr1js", call.getArray("arr1", JSObject.self) as Any)
        // print("arr2", call.getArray("arr2", [String:Any].self) as Any)
        print("arr2", call.getArray("arr2", String.self) as Any)
        print("arr2any", call.getArray("arr2", Any.self) as Any)
        print("arr3", call.getArray("arr2", Any.self) as Any)
        let obj1 = call.options["obj1"]
        print("obj1", obj1 as Any)
        let obj2 = call.options["obj2"] as! JSObject
        print("obj2", obj2 as Any)
        
        call.success([
            // "a": nil, // Not able to pass nil value
            "str1": "",
            "str2": "abc",
            "bool1": false,
            "bool2": true,
            "int1": 0,
            "int2": 123,
            "float1": 123.456,
            "arr1": [],
            "arr2": [1,2,3],
            "arr3": ["a","b","c"],
            "obj1": ["a": 1, "b": "b", "c": true, "d": nil]
            ])
    }
    
}


