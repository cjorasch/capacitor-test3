package com.getcapacitor.myapp;

import com.getcapacitor.NativePlugin;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;

@NativePlugin()
public class ContactsAndroidPlugin extends Plugin {

    @PluginMethod()
    public void customCall(PluginCall call) {
        String message = call.getString("message");
        call.success();
    }
}