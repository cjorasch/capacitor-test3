// ----- iOS Contacts -----

// Use exact same names as iOS
// Interfaces
// Enums
// Static methods

// Plugin interface
export interface ContactsIos {
    unifiedContact({
        withIdentifier: string
    }): {
        contact: CNContact
    }
}

// https://developer.apple.com/documentation/contacts/cnentitytype
const enum CNEntityType {
    contacts
}

// https://developer.apple.com/documentation/contacts/cnauthorizationstatus
enum CNAuthorizationStatus {
    notDetermined, // The Allow/Deny dialog has not yet been displayed
    restricted, // Not able to access (e.g. parental locks)
    denied, // user has clicked the Deny access button
    authorized // The user has clicked the Allow Access button
}

interface CNContact {
    identifier: string;
    contactType: CNContactType;

    namePrefix?: string;
    givenName?: string;
    middleName?: string;
    familyName?: string;
    previousFamilyName?: string;
    nameSuffix?: string;
    nickname?: string;
    phoeneticGivenName?: string;
    phoeneticMiddleName?: string;
    phoeneticFamilyName?: string;
    organizationName?: string;
    departmentName?: string;
    jobTitle?: string;
}

// https://developer.apple.com/documentation/contacts/cncontacttype
const enum CNContactType {
    person,
    organization
}

// https://developer.apple.com/documentation/contacts/cncontactsortorder
const enum CNContactSortOrder {
    none,
    userDefault,
    givenName,
    familyName
}

interface CNGroup {
    identifier: string;
    name: string;
}

interface CNContainer {
    identifier: string;
    name: string;
    type: CNContainerType;
}

// https://developer.apple.com/documentation/contacts/cncontainertype
const enum CNContainerType {
    local, // A container for contacts only stored locally on the device. There is only one local container for a device.
    exchange, // A container for contacts stored in an Exchange folder from an Exchange server.
    cardDAV, // A container for contacts stored in an CardDAV server, such as iCloud.
    unassigned
}

