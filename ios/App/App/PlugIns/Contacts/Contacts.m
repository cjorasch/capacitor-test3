#import <Capacitor/Capacitor.h>

CAP_PLUGIN(Contacts, "Contacts",
           CAP_PLUGIN_METHOD(authorizationStatus, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(requestAccess, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(unifiedContact, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(unifiedContacts, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(groups, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(containers, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(defaultContainerIdentifier, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(enumerateContacts, CAPPluginReturnPromise);

           CAP_PLUGIN_METHOD(addContact, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(updateContact, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(deleteContact, CAPPluginReturnPromise);

           CAP_PLUGIN_METHOD(addGroup, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(updateGroup, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(deleteGroup, CAPPluginReturnPromise);
           
           CAP_PLUGIN_METHOD(addMember, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(removeMember, CAPPluginReturnPromise);

           
           )

