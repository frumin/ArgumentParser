# ArgumentParser

A command line argument parser.

## Usage

```
import ArgumentParser

let parameter = Parameter(name: "--bar", description: "use bar", isRequired: false, valueRequired: false)
let foo = Verb(name: "foo", description: "does foo", parameters: [parameter]) { (parameters) in
    let useBar = try? parameters?.value(for: testParamName) == nil ?? false
    // do foo, possibly with bar
}

CommandLine.parse([foo])
```
