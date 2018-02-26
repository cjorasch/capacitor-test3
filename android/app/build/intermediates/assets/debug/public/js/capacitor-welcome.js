window.customElements.define('capacitor-welcome', class extends HTMLElement {
  constructor() {
    super();

    Capacitor.Plugins.SplashScreen.hide();

    Capacitor.Plugins.Network.getStatus();
    
    const root = this.attachShadow({ mode: 'closed' });

    root.innerHTML = `
    <style>
      :host {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
        display: block;
        width: 100%;
        height: 100%;
      }
      h1, h2, h3, h4, h5 {
        text-transform: uppercase;
      }
      .button {
        display: inline-block;
        padding: 10px;
        background-color: #73B5F6;
        color: #fff;
        font-size: 0.9em;
        border: 0;
        border-radius: 3px;
        text-decoration: none;
      }
      main {
        padding: 15px;
      }
      main hr { height: 1px; background-color: #eee; border: 0; }
      main h1 {
        font-size: 1.4em;
        text-transform: uppercase;
        letter-spacing: 1px;
      }
      main h2 {
        font-size: 1.1em;
      }
      main h3 {
        font-size: 0.9em;
      }
      main p {
        color: #333;
      }
      main pre {
        white-space: pre-line;
      }
    </style>
    <div>
      <capacitor-welcome-titlebar>
        <h1>Capacitor Testing</h1>
      </capacitor-welcome-titlebar>
      <main>
      <h2>Device</h2>
      <p>
      <a onclick="return deviceGetInfo();" href="#">Get Info</a>
    </p> 
    <h2>Android Contacts</h2>
    <p>
    <a onclick="return customCall();" href="#">customCall</a>
  </p> 
        <h2>Contacts</h2>
        <p>
          <a onclick="return authorizationStatus();" href="#">Authorization Status</a>
        </p>        
        <p>
          <a onclick="return requestAccess();" href="#">Request Access</a>
        </p>   
         <p>
         <a onclick="return unifiedContact();" href="#">Unified Contact</a>
         </p>
         <p>
         <a onclick="return unifiedContacts();" href="#">Unified Contacts</a>
         </p>
         <p>
         <a onclick="return groups();" href="#">Groups</a>
         </p>
         <p>
         <a onclick="return containers();" href="#">Containers</a>
         </p>
         <p>
         <a onclick="return defaultContainerIdentifier();" href="#">Default Container Id</a>
         </p>
                             <p>
                             <a onclick="return enumerateContacts();" href="#">Enumerate Contacts</a>
                             </p>
         <p>
         <a onclick="return addContact();" href="#">Add Contact</a>
         </p>
                             <p>
                             <a onclick="return updateContact();" href="#">Update Contact</a>
                             </p>
                             <p>
                             <a onclick="return deleteContact();" href="#">Delete Contact</a>
                             </p>
                             
                             <p>
                             <a onclick="return addGroup();" href="#">Add Group</a>
                             </p>
                             <p>
                             <a onclick="return updateGroup();" href="#">Update Group</a>
                             </p>
                             <p>
                             <a onclick="return deleteGroup();" href="#">Delete Group</a>
                             </p>
         <p>
         <a onclick="return test();" href="#">Test</a>
         </p>
         </main>
    </div>
    `
  }
});

var Contacts = Capacitor.Plugins.Contacts;
var Testing = Capacitor.Plugins.Testing;
var Device = Capacitor.Plugins.Device;
var ContactsAndroidPlugin = Capacitor.Plugins.ContactsAndroidPlugin;
console.log('ContactsAndroidPlugin', ContactsAndroidPlugin);

function deviceGetInfo() {
  return showResult(Device.getInfo());
}

// ContactsAndroidPlugin

function customCall() {
  return showResult(ContactsAndroidPlugin.customCall());
}

// Contacts

if (Contacts) {
  Contacts.addListener('contactStoreDidChange', data => console.log("contactStoreDidChange", data))
}

function showResult(promise) {
    promise
        .then(result => alert(JSON.stringify(result)))
        .catch(error => alert(error.message));
    return false;
}

function authorizationStatus() {
  return showResult(Contacts.authorizationStatus());
}

function requestAccess() {
    return showResult(Contacts.requestAccess());
    return false;
}

function unifiedContact() {
    return showResult(Contacts.unifiedContact({withIdentifier:'AB211C5F-9EC9-429F-9466-B9382FF61035'}));
}

function unifiedContacts() {
    var query = {
        matchingName:'smith'
    }
//    var query = {
//        groupId: 'CCDA4756-71B4-4B25-8DD2-D3DA109F4561'
//    }
    return showResult(Contacts.unifiedContacts(query));
}

function groups() {
    return showResult(Contacts.groups());
}

function containers() {
    return showResult(Contacts.containers());
}

function defaultContainerIdentifier() {
    return showResult(Contacts.defaultContainerIdentifier());
}

function enumerateContacts() {
    return showResult(Contacts.enumerateContacts({keysToFetch:['givenName']}));
}

var tempContactId;
var tempGroupId;

function addContact() {
    var promise = Contacts.addContact({
                                     givenName: 'John',
                                     familyName: 'Smith',
                                      organizationName: 'Apple',
                                      note: 'this is a note',
                                      emailAddresses: [
                                                       { label: 'home', value: 'john@smith.com'}
                                      ],
                                      phoneNumbers: [
                                                     { label: 'work', stringValue: '111-111-1111'}
                                                     ],
                                      postalAddresses: [
                                                        { label: 'home', street: '123 Main Street', city: 'Palo Alto', state: 'CA', postalCode: '94301'}
                                      ]
                                     });
    promise.then(result => tempContactId = result.contact.identifier)
    return showResult(promise);
}

function updateContact() {
    return showResult(Contacts.updateContact({identifier: tempContactId, familyName: 'Smith2'}));
}

function deleteContact() {
    return showResult(Contacts.deleteContact({identifier: tempContactId}));
}

function addGroup() {
    return showResult(Contacts.addGroup({ name: 'TempGroup' }));
}

function updateGroup() {
    return showResult(Contacts.updateGroup({ identifier: '4FB16914-3083-48F7-A8EB-E0C097A5FF90:ABGroup', name: 'TempGroup2' }));
}

function deleteGroup() {
    return showResult(Contacts.deleteGroup({identifier: '4FB16914-3083-48F7-A8EB-E0C097A5FF90:ABGroup'}));
}

function test() {
    return showResult(Testing.callTesting({
                                    str1: '',
                                    str2: 'abc',
                                    str3: null,
                                    str4: window.xyz, // undefined
                                    bool1: false,
                                    bool2: true,
                                    num1: 0,
                                    num2: 123,
                                    num3: 123.456,
                                    arr1: [1, 2, 3],
                                    arr2: ['a', 'b', 'c'],
                                    arr3: ['a', 2, true, null],
                                          obj1: {},
                                          obj2: {a: 1, b: 'c', c: true}
    }));
}

window.customElements.define('capacitor-welcome-titlebar', class extends HTMLElement {
  constructor() {
    super();
    const root = this.attachShadow({ mode: 'closed' });
    root.innerHTML = `
    <style>
      :host {
        position: relative;
        display: block;
        padding: 15px 15px 15px 15px;
        text-align: center;
        background-color: #73B5F6;
      }
      ::slotted(h1) {
        margin: 0;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
        font-size: 0.9em;
        font-weight: 600;
        color: #fff;
      }
    </style>
    <slot></slot>
    `;
  }
})
