package com.getcapacitor.myapp;

import com.getcapacitor.JSObject;
import com.getcapacitor.NativePlugin;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;

// Manifest
//      <uses-permission android:name="android.permission.READ_CONTACTS" />

// https://github.com/apache/cordova-plugin-contacts/blob/master/src/android/ContactAccessorSdk5.java
// https://developer.android.com/guide/topics/providers/contacts-provider.html

@NativePlugin()
public class ContactsAndroidPlugin extends Plugin {

    @PluginMethod()
    public void customCall(PluginCall call) {
        JSObject r = new JSObject();

        r.put("name", "John");

        call.success(r);
    }
}