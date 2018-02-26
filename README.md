## Getting Started

Note: Capacitor requires Node 8.6.0 or later.

```bash
git clone https://github.com/ionic-team/capacitor-starter my-app
cd my-app
npm install
npm run capacitor init
```

## Update Capacitor

Change version numbers in package.json

```
  "dependencies": {
    "@capacitor/cli": "0.0.102",
    "@capacitor/core": "0.0.102"
  }
```

Update the npm modules.  `update` updates core plugins and capacitor libraries.

```bash
npm install
npx capacitor update ios?
```

You should run this command periodically to ensure you have the latest versions of CocoaPods dependencies.

```bash
pod repo update
```

## Development

To update the ios project after making changes to the web source files.

```bash
npm run build
npx capacitor copy ios
```

To open xcode environment

```bash
npx capacitor open ios
```

