import Foundation
import Capacitor
import Contacts

// Use case
//      Populate sign up form
//          getContact({email: x}) => {first, last, image}
//      Populate photo
//          getContact(emails) => [photos]
//      Get extended contact information for a participant
//          getContact(email) => {phones, emails, social, addresses, etc.)
//      Pick contacts when adding participants
//          getContacts(name of email) => {first, last, email, photo}
//      Add contact from particpant
//          addContact({first, last, email}) or merge with existing?

// Contacts
//      https://developer.apple.com/documentation/contacts
//      https://www.safaribooksonline.com/library/view/ios-9-swift/9781491936689/ch04.html
//      https://www.appcoda.com/ios-contacts-framework/
//      https://github.com/joshuapinter/react-native-unified-contacts/blob/master/RNUnifiedContacts/RNUnifiedContacts.swift
//      https://github.com/satishbabariya/SwiftyContacts/blob/master/Sources/Core/SwiftyContacts.swift
//      https://digitalleaves.com/blog/2016/04/managing-contacts-in-swift-addressbook-and-contacts-frameworks/
//      https://code.tutsplus.com/tutorials/ios-9-an-introduction-to-the-contacts-framework--cms-25599
//      https://github.com/apache/cordova-plugin-contacts

// TODO:
//      return value style
//          { result: [Contact] }
//          [Contact] - requires changes in Capacitor
//      error return value style

// TODO: ContactsUI
//      pickContacts() => contacts
//          self.bridge.viewController.present(vc, animated: true, completion: nil)
//     openContact()
//let controller = CNContactViewController(forContact: contact)
//controller.contactStore = self.store
//controller.allowsEditing = false
//
//controller.displayedPropertyKeys =
//    [CNContactEmailAddressesKey, CNContactPostalAddressesKey]
//
//self.navigationController?
//    .pushViewController(controller, animated: true)

// Other utilities
//      dial phone
//      send sms
//      send email

@available(iOS 9.0, *)
@objc(Contacts)
public class Contacts: CAPPlugin {
    
    // Initialization
    public override func load() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onContactStoreDidChange(notification:)),
                                               name: .CNContactStoreDidChange,
                                               object: nil)
    }
    
    // ----- Fetching Unified Contacts -----
    
    #if os(OSX)
    @objc func unifiedMeContactWithKeys(_ call: CAPPluginCall) {
        let keysToFetch = getKeysToFetch(call.getArray("keysToFetch", String.self))
        do {
            let contact = try CNContactStore().unifiedMeContactWithKeys(toFetch:keysToFetch)
            call.success([
                "contact": convertContact(contact)
                ])
        } catch {
            call.error("Unable to load Me contact", error)
        }
    }
    #endif
    
    // Gets a single Contact
    @objc func unifiedContact(_ call: CAPPluginCall) {
        guard let contactId = call.getString("withIdentifier") else {
            call.error("Must specify 'withIdentifier'")
            return
        }
        
        let keysToFetch = getKeyDescriptors(call.getArray("keysToFetch", String.self))
        
        do {
            let contact = try CNContactStore().unifiedContact(withIdentifier: contactId, keysToFetch:keysToFetch)
            call.success([
                "contact": convertContact(contact, keys: keysToFetch) as Any
                ])
        } catch {
            call.error("Unable to load Contact", error)
        }
    }
    
    // Gets a list of contacts
    @objc func unifiedContacts(_ call: CAPPluginCall) {
        // TODO: maxItems?

        // Get the specified predicate
        var predicate: NSPredicate?
        if let matchingName = call.getString("matchingName") {
            // Note: if matchingName is blank then invalid predicate error
            predicate = CNContact.predicateForContacts(matchingName:matchingName)
        } else if let withIdentifiers = call.getArray("withIdentifiers", String.self) {
            predicate = CNContact.predicateForContacts(withIdentifiers: withIdentifiers)
        } else if let groupId = call.getString("groupId") {
            predicate = CNContact.predicateForContactsInGroup(withIdentifier: groupId)
        } else if let containerId = call.getString("containerId") {
            predicate = CNContact.predicateForContactsInContainer(withIdentifier: containerId)
        }
        if predicate == nil {
            call.error("Must specify matching")
            return
        }
        
        let keysToFetch = getKeyDescriptors(call.getArray("keysToFetch", String.self))
        
        do {
            let contacts = try CNContactStore().unifiedContacts(matching: predicate!, keysToFetch: keysToFetch)
            call.success([
                "contacts": convertContacts(contacts, keys: keysToFetch)
                ])
        } catch {
            call.error(error.localizedDescription, error)
        }
    }
    
    // ----- Privacy Access -----
    
    // Get the current authorization status for contacts
    @objc func authorizationStatus(_ call: CAPPluginCall) {
        let entityTypeInt = call.getInt("entityType") ?? CNEntityType.contacts.rawValue
        let entityType = CNEntityType(rawValue:entityTypeInt)
        let status = CNContactStore.authorizationStatus(for:entityType!)
        call.success([
            "status": status.rawValue
            ])
    }
    
    // Request access to Contacts.  Displays a dialog to allow/deny access if first time
    @objc func requestAccess(_ call: CAPPluginCall) {
        // TODO: ability to specify entity type?

        // Check if access has already been granted
        let status = CNContactStore.authorizationStatus(for:CNEntityType.contacts)
        if status == .authorized {
            call.success([
                "status": true
                ])
        }
        
        // Request access
        CNContactStore().requestAccess(for: CNEntityType.contacts) { (userCanAccessContacts, error) in
            if (userCanAccessContacts) {
                call.success([
                    "status": true
                    ])
            } else {
                call.success([
                    "status": false
                    ])
            }
        }
    }
    
    // ----- Fetching and Saving -----
    
    // Get the list of Groups
    @objc func groups(_ call: CAPPluginCall) {
        
        do {
            // Get the predicate
            var predicate: NSPredicate?
            if let identifiers = call.getArray("identifieres", String.self) {
                predicate = CNGroup.predicateForGroups(withIdentifiers: identifiers)
            } else if let containerIdentifier = call.getString("containerIdentifier") {
                predicate = CNGroup.predicateForGroupsInContainer(withIdentifier: containerIdentifier)
            }
            // TODO2: ios10.11 predicateForSubgroupsInGroup(withIdentifier parentGroupIdentifier: String)
            
            // Get the groups
            let result = try CNContactStore().groups(matching: predicate)
            
            // Return the result
            call.success([
                "result": convertGroups(result)
                ])
        } catch let error as NSError {
            call.error(error.localizedDescription)
        }
    }
    
    // Get the list of Containers
    @objc func containers(_ call: CAPPluginCall) {
        do {
            // Get the container predicate
            var predicate: NSPredicate?
            if let contactIdentifier = call.getString("contactIdentifier") {
                predicate = CNContainer.predicateForContainerOfContact(withIdentifier: contactIdentifier)
            } else if let identifiers = call.getArray("identifiers", String.self) {
                predicate = CNContainer.predicateForContainers(withIdentifiers: identifiers)
            } else if let groupIdentifier = call.getString("groupIdentifier") {
                predicate = CNContainer.predicateForContainerOfGroup(withIdentifier: groupIdentifier)
            }
            
            // Get the containers
            let result = try CNContactStore().containers(matching: predicate)
            
            // Return the result
            call.success([
                "result": convertContainers(result)
                ])
        } catch let error as NSError {
            call.error(error.localizedDescription)
        }
    }
    
    // Gets the identifier for the default contact container
    @objc func defaultContainerIdentifier(_ call: CAPPluginCall) {
        let result = CNContactStore().defaultContainerIdentifier()
        call.success([
            "result": result
            ])
    }
    
    // Get a list of Contacts
    @objc func enumerateContacts(_ call: CAPPluginCall) {
        // TODO: query criteria
        //      where: { property: 'givenName', comparison: Comparison.STARTS_WITH, value: 'c' }
        let store = CNContactStore()
        do {
            // Initialize the array of results
            var contacts = [CNContact]()
            
            // Specify the keys to load
            let keysToFetch = getKeyDescriptors(call.getArray("keysToFetch", String.self))
            
            // Step through all of the Contacts
            try store.enumerateContacts(with:CNContactFetchRequest(keysToFetch: keysToFetch)) { (contact, pointer) -> Void in
                // TODO: check search criteria
                contacts.append(contact)
            }
            
            call.success([
                "contacts": convertContacts(contacts, keys: keysToFetch)
                ])
        } catch let error as NSError {
            call.error(error.localizedDescription, error)
        }
    }
    
    // ----- Notifications -----
    
    // Raise event when contact store has changed
    @objc func onContactStoreDidChange(notification: NSNotification) {
        // TODO: what data to pass to listeners?
        // data: notification.userInfo as! [String: Any]
        notifyListeners("contactStoreDidChange", data: [
            "contactsChanged": true
            ], retainUntilConsumed: true)
    }
    
    // ----- CNSaveRequest -----
    
    // Gets a CNContact by id or return nil if not found
    func getContact(_ identifier: String, keys: [String]? = nil) -> CNContact? {
        let keysToFetch = getKeyDescriptors(keys)
        do {
            let contact = try CNContactStore().unifiedContact(withIdentifier: identifier, keysToFetch:keysToFetch)
            return contact
        } catch {
            return nil
        }
    }
    
    // Adds a Contact
    @objc func addContact(_ call: CAPPluginCall) {
        // TODO:
        //      return nothing?  identifier?  contact?
        //      support adding batch of contacts at same time
        //          transaction that includes list of insert, update, deletes?
        do {
            let containerId: String? = nil
            
            // Create a mutable contact
            let contact = CNMutableContact()
            
            // TODO: how to convert?
            let keys = call.options!.keys.map {"\($0)"}
            for key in keys {
                if let value = call.options[key] {
                    setContactProp(contact, key, value)
                }
            }
            
            // Add the contact
            let saveRequest = CNSaveRequest()
            saveRequest.add(contact, toContainerWithIdentifier:containerId)
            try CNContactStore().execute(saveRequest)

            call.success([
                "contact": convertContact(contact, keys: allKeys) as Any
                ]);
        } catch {
                call.error(error.localizedDescription, error)
        }
    }
    
    // Updates an existing Contact
    @objc func updateContact(_ call: CAPPluginCall) {
        // TODO: PATCH vs. PUT style updates?
        //      updatePhone distinct from updateContact?
        //      changes as property vs. all root props?  changes = options["changes"] as? JSObject
        let keys = call.options!.keys.map {"\($0)"}
        do {
            // Get the contact id from the args
            guard let identifier = call.getString("identifier") else {
                call.error("Must specify 'identifier'")
                return
            }
            
            // Get the contact based on the id
            guard let existingContact = getContact(identifier, keys: keys) else {
                // Note: important to have update fail because changes are lost
                call.error("Contact not found for identifier '\(identifier)'")
                return
            }
            
            // Create a mutable copy of the contact
            let contact = existingContact.mutableCopy() as! CNMutableContact
            
            // Update the contact
            for key in keys {
                // Skip the identifier since it can not be updated
                if key != "identifier" {
                    if let value = call.options[key] {
                        setContactProp(contact, key, value)
                    }
                }
            }
            
            // TODO: ability to update existing child objects (e.g. phone numbers) vs. override all numbers
            
            // Update the Contact
            let saveRequest = CNSaveRequest()
            saveRequest.update(contact)
            try CNContactStore().execute(saveRequest)
            
            call.success([
                "contact": convertContact(contact, keys: keys as [CNKeyDescriptor]) as Any
                ]);
        } catch {
            call.error(error.localizedDescription, error)
        }
    }
    
    // Deletes a Contact
    @objc func deleteContact(_ call: CAPPluginCall) {
        do {
            // Get the contact id from the arguments
            guard let identifier = call.getString("identifier") else {
                call.error("Must specify 'identifier'")
                return
            }
            
            // Get the contact to be deleted
            guard let existingContact = getContact(identifier, keys: []) else {
                call.success([
                    "count": 0
                    ]);
                return
            }
            
            // Convert to CNMutableContact since that is required for delete
            let contact = existingContact.mutableCopy() as! CNMutableContact
            
            // Delete the Contact
            let saveRequest = CNSaveRequest()
            saveRequest.delete(contact)
            try CNContactStore().execute(saveRequest)
            
            // Indicate success
            call.success([
                "count": 1
                ]);
        } catch {
            call.error(error.localizedDescription, error)
        }
    }
    
    // Gets a CNGroup based on an id
    func getGroup(_ identifier: String) -> CNGroup? {
        do {
            let matching = CNGroup.predicateForGroups(withIdentifiers: [identifier])
            let groups = try CNContactStore().groups(matching: matching)
            if groups.count == 0 {
                return nil
            }
            return groups.first
        } catch {
            return nil
        }
    }
    
    // Adds a CNGroup
    @objc func addGroup(_ call: CAPPluginCall) {
        
        do {
            let group = CNMutableGroup()
            
            guard let name = call.getString("name") else {
                call.error("Must specify 'name'")
                return
            }
            let container = call.getString("container")
            
            group.name = name
            
            let saveRequest = CNSaveRequest()
            saveRequest.add(group, toContainerWithIdentifier: container)
            try CNContactStore().execute(saveRequest)
            
            // Indicate success
            call.success([
                "group": convertGroup(group)
                ]);
        } catch {
            call.error(error.localizedDescription, error)
        }
    }
    
    // Updates a CNGroup
    @objc func updateGroup(_ call: CAPPluginCall) {
        do {
            guard let identifier = call.getString("identifier") else {
                call.error("Must specify 'identifier'")
                return
            }
            
            guard let existingGroup = getGroup(identifier) else {
                // Note: import to have error vs. silent fail since update does not occur if group not found
                call.error("Group not found for identifier '\(identifier)'")
                return
            }
            
            // Make a mutable copy of the group
            let group = existingGroup.mutableCopy() as! CNMutableGroup
            
            // Update the Group
            if let name = call.getString("name") {
                group.name = name
            }
            
            // Update the group
            let saveRequest = CNSaveRequest()
            saveRequest.update(group)
            try CNContactStore().execute(saveRequest)
            
            call.success([
                "group": convertGroup(group)
                ]);
        } catch {
            call.error(error.localizedDescription, error)
        }
    }
    
    // Deletes a CNGroup
    @objc func deleteGroup(_ call: CAPPluginCall) {
        do {
            // Get the specified group id
            guard let identifier = call.getString("identifier") else {
                call.error("Must specify 'identifier'")
                return
            }
            
            // Get the group based on the id
            guard let existingGroup = getGroup(identifier) else {
                call.success([
                    "count": 0
                    ]);
                return
            }
            
            // Make a mutable copy of the group
            let group = existingGroup.mutableCopy() as! CNMutableGroup
            
            // Delete the group
            let saveRequest = CNSaveRequest()
            saveRequest.delete(group)
            try CNContactStore().execute(saveRequest)
            
            // Indicate success
            call.success([
                "count": 1
                ]);
        } catch {
            call.error("Unable to delete the group", error)
        }
    }
    
    // Add a Contact to a Group
    @objc func addMember(_ call: CAPPluginCall) {
        // TODO2: support adding multiple contacts at the same time
        do {
            // Get the specified contact id
            guard let contactId = call.getString("contactId") else {
                call.error("Must specify 'contactId'.")
                return
            }
            
            // Get the contact based on the id
            guard let contact = getContact(contactId, keys: []) else {
                call.error("The contact '\(contactId)' was not found.")
                return
            }
            
            // Get the specified group id
            guard let groupId = call.getString("groupId") else {
                call.error("Must specify 'groupId'.")
                return
            }
            
            // Get the group based on the id
            guard let group = getGroup(groupId) else {
                call.error("The group '\(groupId)' was not found.")
                return
            }
            
            // Add the member
            let saveRequest = CNSaveRequest()
            saveRequest.addMember(contact, to: group)
            try CNContactStore().execute(saveRequest)
            
            // Indicate success
            call.success();
        } catch {
            call.error("Unable to add the contact to the group", error)
        }
    }
    
    // Remove a Contact from a Group
    @objc func removeMember(_ call: CAPPluginCall) {
        do {
            // Get the specified contact id
            guard let contactId = call.getString("contactId") else {
                call.error("Must specify 'contactId'.")
                return
            }
            
            // Get the contact based on the id
            guard let contact = getContact(contactId, keys: []) else {
                call.error("The contact '\(contactId)' was not found.")
                return
            }
            
            // Get the specified group id
            guard let groupId = call.getString("groupId") else {
                call.error("Must specify 'groupId'.")
                return
            }
            
            // Get the group based on the id
            guard let group = getGroup(groupId) else {
                call.error("The group '\(groupId)' was not found.")
                return
            }
            
            // Remove the member
            let saveRequest = CNSaveRequest()
            saveRequest.removeMember(contact, from: group)
            try CNContactStore().execute(saveRequest)
            
            // Indicate success
            call.success();
        } catch {
            call.error("Unable to remove the contact from the group", error)
        }
    }
    
    // ========== Private Members ==========
    
    // ----- CNKeyDescriptor -----
    
    let noKeys = [] as [CNKeyDescriptor]
    
    let allKeys = [
        CNContactBirthdayKey,
        CNContactDatesKey,
        CNContactDepartmentNameKey,
        CNContactEmailAddressesKey,
        CNContactFamilyNameKey,
        CNContactGivenNameKey,
        CNContactIdentifierKey,
        CNContactImageDataAvailableKey,
        //    CNContactImageDataKey,
        CNContactInstantMessageAddressesKey,
        CNContactJobTitleKey,
        CNContactMiddleNameKey,
        CNContactNamePrefixKey,
        CNContactNameSuffixKey,
        CNContactNicknameKey,
        CNContactNonGregorianBirthdayKey,
        CNContactNoteKey,
        CNContactOrganizationNameKey,
        CNContactPhoneNumbersKey,
        CNContactPhoneticFamilyNameKey,
        CNContactPhoneticGivenNameKey,
        CNContactPhoneticMiddleNameKey,
        // CNContactPhoneticOrganizationNameKey,
        CNContactPostalAddressesKey,
        CNContactPreviousFamilyNameKey,
        CNContactRelationsKey,
        CNContactSocialProfilesKey,
        CNContactThumbnailImageDataKey,
        CNContactTypeKey,
        CNContactUrlAddressesKey,
        ] as [CNKeyDescriptor]
    
    // Convert list of keys to [CNKeyDescriptor] with default value if not specified
    private func getKeyDescriptors(_ keys: [String]?) -> [CNKeyDescriptor] {
        if keys == nil {
            return allKeys
        } else {
            return keys! as [CNKeyDescriptor]
        }
    }
    
    // ----- CNGroup -----
    
    // Convert [CNGroup] to JSArray
    private func convertGroups(_ groups: [CNGroup]) -> JSArray {
        var result = JSArray()
        for group in groups {
            let item = convertGroup(group)
            result.append(item)
        }
        return result
    }
    
    // Convert CNGroup to JSObject
    private func convertGroup(_ group: CNGroup) -> JSObject {
        var result = JSObject()
        
        result["identifier"] = group.identifier
        result["name"] = group.name
        
        return result
    }
    
    // ----- CNContainer -----
    
    // Convert [CNContainer] to JSArray
    private func convertContainers(_ containers: [CNContainer]) -> JSArray {
        var result = JSArray()
        for container in containers {
            let item = convertContainer(container)
            result.append(item)
        }
        return result
    }
    
    // Convert CNContainer to JSObject
    private func convertContainer(_ container: CNContainer) -> JSObject {
        var result = JSObject()
        
        result["identifier"] = container.identifier
        result["name"] = container.name
        result["type"] = container.type.rawValue
        
        return result
    }
    
    // ----- CNContact -----
    
    // Convert [CNContact] to JSArray
    private func convertContacts(_ nativeContacts: [CNContact], keys: [CNKeyDescriptor]) -> JSArray {
        var contacts = JSArray()
        for nativeContact in nativeContacts {
            if let contact = convertContact(nativeContact, keys: keys) {
                contacts.append(contact)
            }
        }
        return contacts
    }
    
    // Convert CNContact to JSObject
    private func convertContact(_ nativeContact: CNContact?, keys: [CNKeyDescriptor]) -> JSObject? {
        
        // TODO: omit blank values?  e.g. organizationName
        //      only return identifier if requested
        //      keys as arg so only process list of keys vs. checking all fields
        
        if nativeContact == nil {
            return nil
        }
        let contact = nativeContact!
        
        var result = JSObject()
        
        if keys.index(where: {$0 === "identifier" as CNKeyDescriptor}) != nil {
            result["identifier"] = contact.identifier
        }
//        let id = CNContactIdentifierKey as CNKeyDescriptor
//        if keys.index(of: id) != nil {
//            result["identifier"] = contact.identifier
//        }
        if contact.isKeyAvailable("contactType") {
            result["contactType"] = contact.contactType.rawValue
        }
        
        // birthday
        // nonGregorianBirthday
        // dates
        // imageDataAvailable
        // thumbnailImageData
        // fullName: CNContactFormatter.string( from: contact, style: .fullName )
        //      request fullName
        //      need to include keysToFetch if fullName specified
        
        if contact.isKeyAvailable("namePrefix") {
            setProp(&result, "namePrefix", contact.namePrefix)
        }
        if contact.isKeyAvailable("givenName") {
            setProp(&result, "givenName", contact.givenName)
        }
        if contact.isKeyAvailable("middleName") {
            setProp(&result, "middleName", contact.middleName)
        }
        if contact.isKeyAvailable("familyName") {
            setProp(&result, "familyName", contact.familyName)
        }
        if contact.isKeyAvailable("previousFamilyName") {
            setProp(&result, "previousFamilyName", contact.previousFamilyName)
        }
        if contact.isKeyAvailable("nameSuffix") {
            setProp(&result, "nameSuffix", contact.nameSuffix)
        }
        if contact.isKeyAvailable("nickname") {
            setProp(&result, "nickname", contact.nickname)
        }
        if contact.isKeyAvailable("phoneticGivenName") {
            setProp(&result, "phoneticGivenName", contact.phoneticGivenName)
        }
        if contact.isKeyAvailable("phoneticMiddleName") {
            setProp(&result, "phoneticMiddleName", contact.phoneticMiddleName)
        }
        if contact.isKeyAvailable("phoneticFamilyName") {
            setProp(&result, "phoneticFamilyName", contact.phoneticFamilyName)
        }
        if contact.isKeyAvailable("organizationName") {
            setProp(&result, "organizationName", contact.organizationName)
        }
        if contact.isKeyAvailable("departmentName") {
            setProp(&result, "departmentName", contact.departmentName)
        }
        if contact.isKeyAvailable("jobTitle") {
            setProp(&result, "jobTitle", contact.jobTitle)
        }
        
        if contact.isKeyAvailable("phoneNumbers") && contact.phoneNumbers.count > 0 {
            result["phoneNumbers"] = contact.phoneNumbers.map { (item) -> [String: Any] in
                var dict = convertLabeledValue(item)
                setProp(&dict, "stringValue", item.value.stringValue)
                setProp(&dict, "countryCode",item.value.value(forKey: "countryCode") as? String)
                setProp(&dict, "digits", item.value.value(forKey: "digits") as? String)
                return dict
            }
        }
        
        if contact.isKeyAvailable("emailAddresses") && contact.emailAddresses.count > 0 {
            result["emailAddresses"] = contact.emailAddresses.map { (item) -> [String: Any] in
                var dict = convertLabeledValue(item)
                setProp(&dict, "value", item.value as String)
                return dict
            }
        }
        
        if contact.isKeyAvailable("postalAddresses") && contact.postalAddresses.count > 0 {
            result["postalAddresses"] = contact.postalAddresses.map { (item) -> [String: Any] in
                var dict = convertLabeledValue(item)
                let value = item.value
                setProp(&dict, "street", value.street)
                setProp(&dict, "city", value.city)
                setProp(&dict, "state", value.state)
                setProp(&dict, "postalCode", value.postalCode)
                setProp(&dict, "country", value.country)
                setProp(&dict, "isoCountryCode",value.isoCountryCode)
                setProp(&dict, "mailingAddress", CNPostalAddressFormatter.string(from: value, style: .mailingAddress))
                return dict
            }
        }
        
        if contact.isKeyAvailable("instantMessageAddresses") && contact.instantMessageAddresses.count > 0 {
            result["instantMessageAddresses"] = contact.instantMessageAddresses.map { (item) -> [String: Any] in
                var dict = convertLabeledValue(item)
                setProp(&dict, "service", item.value.service)
                setProp(&dict, "localizedService", CNInstantMessageAddress.localizedString(forService: item.value.service))
                setProp(&dict, "username", item.value.username)
                return dict
            }
        }
        
        if contact.isKeyAvailable("socialProfiles") && contact.socialProfiles.count > 0 {
            result["socialProfiles"] = contact.socialProfiles.map { (item) -> [String: Any] in
                var dict = convertLabeledValue(item)
                setProp(&dict, "urlString", item.value.urlString)
                setProp(&dict, "username", item.value.username)
                setProp(&dict, "userIdentifier", item.value.userIdentifier)
                setProp(&dict, "service", item.value.service)
                setProp(&dict, "localizedService",CNSocialProfile.localizedString(forService: item.value.service))
                return dict
            }
        }
        
        if contact.isKeyAvailable("urlAddresses") && contact.urlAddresses.count > 0 {
            result["urlAddresses"] = contact.urlAddresses.map { (item) -> [String: Any] in
                var dict = convertLabeledValue(item)
                setProp(&dict, "value",item.value as String)
                return dict
            }
        }
        
        if contact.isKeyAvailable("contactRelations") && contact.contactRelations.count > 0 {
            result["contactRelations"] = contact.contactRelations.map { (item) -> [String: Any] in
                var dict = convertLabeledValue(item)
                setProp(&dict, "name", item.value.name)
                return dict
            }
        }
        
        return result;
    }
    
    // Convert CNLabeledValue<T> to serializable value
    private func convertLabeledValue<T>(_ item: CNLabeledValue<T>) -> JSObject {
        var dict = JSObject()
        dict["identifier"] = item.identifier
        if var label = item.label {
            if label.hasPrefix("_$!<") && label.hasSuffix(">!$_") {
                let start = label.index(label.startIndex, offsetBy: 4)
                let end = label.index(label.endIndex, offsetBy: -4)
                label = String(label[start..<end])
            }
            setProp(&dict, "label", label)
        }
        // setProp(&dict, "localizedLabel", item.label == nil ? nil : CNLabeledValue<T>.localizedString(forLabel: item.label!))
        return dict
    }
    
    // TODO: check for empty and trim?  or pass through actual values?
    // Set a property value if a value is not blank
    private func setProp(_ dict: inout [String: Any], _ key: String, _ value: String?) {
        // Ignore if value is nil or empty
        if let value = value, !value.isEmpty {
            // TODO: why trim?
            // Trim whitespace
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Ignore if trimmed value is empty
            if (!trimmed.isEmpty) {
                // Set the property value
                dict[key] = value
            }
        }
    }
    
    // Sets a contact string property value
    private func setContactProp(_ contact: CNMutableContact, _ key: String, _ value: Any) {
        switch key {
            // String properties
        case CNContactDepartmentNameKey: contact.departmentName = value as? String ?? ""
        case CNContactFamilyNameKey: contact.familyName = value as? String ?? ""
        case CNContactGivenNameKey: contact.givenName = value as? String ?? ""
        case CNContactJobTitleKey: contact.jobTitle = value as? String ?? ""
        case CNContactMiddleNameKey: contact.middleName = value as? String ?? ""
        case CNContactNamePrefixKey: contact.namePrefix = value as? String ?? ""
        case CNContactNameSuffixKey: contact.nameSuffix = value as? String ?? ""
        case CNContactNicknameKey: contact.nickname = value as? String ?? ""
        case CNContactNoteKey: contact.note = value as? String ?? ""
        case CNContactOrganizationNameKey: contact.organizationName = value as? String ?? ""
        case CNContactPhoneticFamilyNameKey: contact.phoneticFamilyName = value as? String ?? ""
        case CNContactPhoneticGivenNameKey: contact.phoneticGivenName = value as? String ?? ""
        case CNContactPhoneticOrganizationNameKey: contact.phoneticOrganizationName = value as? String ?? ""
        case CNContactPhoneticMiddleNameKey: contact.phoneticMiddleName = value as? String ?? ""
        case CNContactPreviousFamilyNameKey: contact.previousFamilyName = value as? String ?? ""
            
        // Read only properties
        // TODO: error or ignore?
//        case CNContactImageDataAvailableKey: break
//        case CNContactIdentifierKey: break
            
        // [CNLabeledValue<T>] properties
        case CNContactEmailAddressesKey: contact.emailAddresses = createEmailAddresses(value as? JSArray ?? [])
        case CNContactPhoneNumbersKey: contact.phoneNumbers = createPhoneNumbers(value as? JSArray ?? [])
        case CNContactPostalAddressesKey: contact.postalAddresses = createPostalAddresses(value as? JSArray ?? [])
        case CNContactInstantMessageAddressesKey: contact.instantMessageAddresses = createInstantMessageAddresses(value as? JSArray ?? [])
        case CNContactUrlAddressesKey: contact.urlAddresses = createUrlAddresses(value as? JSArray ?? [])
        case CNContactRelationsKey: contact.contactRelations = createContactRelations(value as? JSArray ?? [])
        case CNContactSocialProfilesKey: contact.socialProfiles = createSocialProfiles(value as? JSArray ?? [])

        default: print("Unable to set contact property '\(key)'")
        }
        
        //CNContactBirthdayKey, // DateComponents?
        //CNContactDatesKey, // [CNLabeledValue<NSDateComponents>]
        //CNContactImageDataKey, // Data
        //CNContactNonGregorianBirthdayKey, // DateComponents?
        //CNContactThumbnailImageDataKey, // Data
        //CNContactTypeKey, // CNContactType
    }
    
    func createPhoneNumbers(_ phoneNumbers: JSArray) -> [CNLabeledValue<CNPhoneNumber>] {
        // https://medium.com/swift-and-ios-writing/working-with-phone-numbers-in-swift-6ec698ce0385
        var result = [CNLabeledValue<CNPhoneNumber>]()
        
        for phoneNumber in phoneNumbers {
            var label: String
            switch (phoneNumber["label"] as? String ?? "") {
            case "home":
                label = CNLabelHome
            case "work":
                label = CNLabelWork
            case "mobile":
                label = CNLabelPhoneNumberMobile
            case "iPhone":
                label = CNLabelPhoneNumberiPhone
            case "main":
                label = CNLabelPhoneNumberMain
            case "home fax":
                label = CNLabelPhoneNumberHomeFax
            case "work fax":
                label = CNLabelPhoneNumberWorkFax
            case "pager":
                label = CNLabelPhoneNumberPager
            case "other":
                label = CNLabelOther
            default:
                label = ""
            }
            
            result.append(CNLabeledValue(
                label: label,
                value: CNPhoneNumber(stringValue: phoneNumber["stringValue"] as? String ?? "")
            ))
        }
        
        return result
        
    }
    
    func createEmailAddresses(_ emailAddresses: JSArray) -> [CNLabeledValue<NSString>] {
        var result = [CNLabeledValue<NSString>]()
        
        for emailAddress in emailAddresses {
            var label: String
            switch (emailAddress["label"] as? String ?? "") {
            case "home":
                label = CNLabelHome
            case "work":
                label = CNLabelWork
            case "iCloud":
                label = CNLabelEmailiCloud
            case "other":
                label = CNLabelOther
            default:
                label = ""
            }
            
            result.append(CNLabeledValue(
                label: label,
                value: emailAddress["value"] as? NSString ?? ""
            ))
        }
        
        return result

    }
    
    func createUrlAddresses(_ items: JSArray) -> [CNLabeledValue<NSString>] {
        var result = [CNLabeledValue<NSString>]()
        
        for item in items {
            var label: String
            switch (item["label"] as? String ?? "") {
            case "home":
                label = CNLabelHome
            case "work":
                label = CNLabelWork
            case "home page":   // TODO: value?
                label = CNLabelURLAddressHomePage // _$!<HomePage>!$_
            case "other":
                label = CNLabelOther
            default:
                label = ""
            }
            
            result.append(CNLabeledValue(
                label: label,
                value: item["value"] as? NSString ?? ""
            ))
        }
        
        return result
        
    }
    
    func createPostalAddresses(_ postalAddresses: JSArray) -> [CNLabeledValue<CNPostalAddress>] {
        var result = [CNLabeledValue<CNPostalAddress>]()
        
        for postalAddress in postalAddresses {
            var label: String
            switch (postalAddress["label"] as? String ?? "") {
            case "home":
                label = CNLabelHome
            case "work":
                label = CNLabelWork
            case "other":
                label = CNLabelOther
            default:
                label = ""
            }
            // home / work / other / custom in Contacts.  How to keep custom values?
        
            
            let value = CNMutablePostalAddress()
            if let street = postalAddress["street"] as? String {
                value.street = street
            }
if #available(iOS 10.3, *) {
            if let subLocality = postalAddress["subLocality"] as? String {
                value.subLocality = subLocality
            }
}
            if let city = postalAddress["city"] as? String {
                value.city = city
            }
if #available(iOS 10.3, *) {
            if let subAdministrativeArea = postalAddress["subAdministrativeArea"] as? String {
                value.subAdministrativeArea = subAdministrativeArea
            }
}
            if let state = postalAddress["state"] as? String {
                value.state = state
            }
            if let postalCode = postalAddress["postalCode"] as? String {
                value.postalCode = postalCode
            }
            if let country = postalAddress["country"] as? String {
                value.country = country
            }
            if let isoCountryCode = postalAddress["isoCountryCode"] as? String {
                value.isoCountryCode = isoCountryCode
            }
            // TODO: error for other unknow values?
            //  setPostalAddressProp(address, key, value)?
            result.append(CNLabeledValue(
                label: label,
                value: value
            ))
        }
        
        return result
        
    }
    
    func createInstantMessageAddresses(_ instantMessageAddresses: JSArray) -> [CNLabeledValue<CNInstantMessageAddress>] {
        var result = [CNLabeledValue<CNInstantMessageAddress>]()
        
        for instantMessageAddress in instantMessageAddresses {
            var label: String
            switch (instantMessageAddress["label"] as? String ?? "") {
            case "home":
                label = CNLabelHome
            case "work":
                label = CNLabelWork
            case "other":
                label = CNLabelOther
            default:
                label = ""
            }
            
            result.append(CNLabeledValue(
                label: label,
                value: CNInstantMessageAddress(username: instantMessageAddress["username"] as? String ?? "", service: instantMessageAddress["service"] as? String ?? "")
            ))
        }
        
        return result
        
    }
    
    func createContactRelations(_ items: JSArray) -> [CNLabeledValue<CNContactRelation>] {
        var result = [CNLabeledValue<CNContactRelation>]()
        
        for item in items {
            var label: String
            switch (item["label"] as? String ?? "") {
            case "home":
                label = CNLabelHome
            case "work":
                label = CNLabelWork
            case "other":
                label = CNLabelOther
            default:
                label = ""
            }
            
            result.append(CNLabeledValue(
                label: label,
                value: CNContactRelation(name: item["name"] as? String ?? "")
            ))
        }
        
        return result
        
    }
    
    func createSocialProfiles(_ items: JSArray) -> [CNLabeledValue<CNSocialProfile>] {
        var result = [CNLabeledValue<CNSocialProfile>]()
        
        for item in items {
            var label: String
            switch (item["label"] as? String ?? "") {
            case "home":
                label = CNLabelHome
            case "work":
                label = CNLabelWork
            case "other":
                label = CNLabelOther
            default:
                label = ""
            }
            
            result.append(CNLabeledValue(
                label: label,
                value: CNSocialProfile(urlString: item["urlString"] as? String, username: item["username"] as? String, userIdentifier: item["userIdentifier"] as? String, service: item["service"] as? String)
            ))
        }
        
        return result
        
    }
    
}



