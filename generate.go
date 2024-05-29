package main

import (
	"flag"
	"fmt"
	"os"
	"strings"
)

// Assuming a constructor with known parameters for demonstration
const singletonFile = "src/Singleton.sol"

func main() {
	// Define a string flag for the filename
	filenamePtr := flag.String("filename", "generatedFactory.sol", "Output file name for the generated.sol file")
	factoryFlag := flag.Bool("factory", false, "Run factory generator")
	setupFlag := flag.Bool("setup", false, "Run setup generator")
	flag.Parse()

	// Parse the constructor signature
	parsedConstructor, err := parseConstructorSignature(singletonFile)
	if err != nil {
		fmt.Println("Error Parsing Constructor")
	}

	if *factoryFlag {
		generatedFactory := generateFactory(parsedConstructor)

		err = writeToFile(*filenamePtr, generatedFactory)
		if err != nil {
			fmt.Println("Error Writing Factory")
			return
		}
	}
	if *setupFlag {
		generatedSetup := generateSetup(parsedConstructor)

		err = writeToFile("test/recon/Setup.sol", generatedSetup)
		if err != nil {
			fmt.Println("Error Writing Setup")
			return
		}
	}

}

// // SPDX-License-Identifier: GPL-2.0
// pragma solidity ^0.8.0;

// import {BaseSetup} from "lib/chimera/src/BaseSetup.sol";
// import "src/Factory.sol";

// abstract contract Setup is BaseSetup {
//     Factory public factory;
//     Singleton public target;
//     OrderModule public orderModule;
//     MatchingModule public matchingModule;
//     OrderModule public orderModule;
//     OrderModule public orderModule;

//     function setup() internal virtual override {
//         factory = new Factory();

//     }
// }

func parseConstructorSignature(filePath string) ([]string, error) {
	// Read the file content
	content, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read file: %v", err)
	}

	// Convert the content to string
	fileContent := string(content)

	// Find the constructor signature
	constructorStart := strings.Index(fileContent, "constructor(")
	if constructorStart == -1 {
		return nil, fmt.Errorf("constructor not found in file")
	}

	// Extract the parameters within the parentheses
	constructorEnd := strings.Index(fileContent[constructorStart:], ")")
	if constructorEnd == -1 {
		return nil, fmt.Errorf("could not find closing parenthesis for constructor")
	}
	constructorParams := fileContent[constructorStart+12 : constructorStart+12+constructorEnd]
	// Split the parameters into individual parts
	params := strings.Split(strings.TrimSpace(constructorParams), ",")

	// Initialize a slice to hold the address parameter names
	addressParams := []string{}

	// Iterate over the parameters and check if they are addresses
	for _, param := range params {
		// Remove whitespace around the parameter name and split it into type and name
		splitParam := strings.Split(strings.TrimSpace(param), " ")
		if len(splitParam) < 2 {
			continue // Skip invalid parameters
		}
		paramType := splitParam[0]
		paramName := splitParam[1]

		// Check if the parameter is an address
		if paramType == "address" {
			addressParams = append(addressParams, paramName)
		}
	}

	// Check if the last character of the last item in addressParams is ")"
	// and remove it if so
	if len(addressParams) > 0 {
		lastItem := addressParams[len(addressParams)-1]
		if strings.HasSuffix(lastItem, ")") {
			lastItem = lastItem[:len(lastItem)-1]          // Remove the trailing ")"
			addressParams[len(addressParams)-1] = lastItem // Update the last item in the slice
		}
	}

	return addressParams, nil
}

func generateFactory(parsedConstructor []string) string {
	var sb strings.Builder

	sb.WriteString("// SPDX-License-Identifier: UNLICENSED\n")
	sb.WriteString("pragma solidity ^0.8.0;\n\n")

	// Import statements
	sb.WriteString("import {Singleton} from \"src/Singleton.sol\";\n")

	for _, param := range parsedConstructor {
		sb.WriteString("import {" + formatString(param) + "} from \"src/Modules/" + formatString(param) + ".sol\";\n")
	}

	sb.WriteString("contract Factory {\n")
	sb.WriteString("\tSingleton internal singleton;\n\n")

	for _, param := range parsedConstructor {
		sb.WriteString("\t" + formatString(param) + " internal " + param + ";\n")
	}
	sb.WriteString("\n\tconstructor() { \n")

	for _, param := range parsedConstructor {
		sb.WriteString("\t" + param + "= new " + formatString(param) + "();\n")
	}

	sb.WriteString("\n\tsingleton = new Singleton(\n")

	for _, param := range parsedConstructor {
		sb.WriteString("        address(" + param + "), \n")
	}
	removeLastChars(&sb, 3)
	sb.WriteString("\n   );\n  }\n")
	sb.WriteString("\tfunction getContracts() \n\t external \n\t returns (Singleton, ")

	for _, param := range parsedConstructor {
		sb.WriteString(formatString(param) + ", ")
	}
	removeLastChars(&sb, 2)
	sb.WriteString(")\n\t{\n\t\t return (singleton, ")
	for _, param := range parsedConstructor {
		sb.WriteString(param + ", ")
	}
	removeLastChars(&sb, 2)
	sb.WriteString(");\n\t}\n}")

	return sb.String()
}

func generateSetup(parsedConstructor []string) string {
	var sb strings.Builder

	sb.WriteString("// SPDX-License-Identifier: GPL-2.0\n")
	sb.WriteString("pragma solidity ^0.8.0;\n\n")

	// Import statements
	sb.WriteString("import {BaseSetup} from \"lib/chimera/src/BaseSetup.sol\";\n")
	sb.WriteString("import \"src/Factory.sol\";\n\n")
	sb.WriteString("abstract contract Setup is BaseSetup {\n")
	sb.WriteString("\tFactory public factory;\n")
	sb.WriteString("\tSingleton public target;\n\n")

	for _, param := range parsedConstructor {
		sb.WriteString("\t" + formatString(param) + " public " + param[1:] + ";\n")
	}
	sb.WriteString("\n\tfunction setup() internal virtual override {\n")
	sb.WriteString("\t factory = new Factory();\n")
	sb.WriteString("\t (target, ")

	for _, param := range parsedConstructor {
		sb.WriteString(param[1:] + ", ")
	}
	removeLastChars(&sb, 2)
	sb.WriteString(") = factory.getContracts();\n\t}\n}")
	return sb.String()
}

// function to convert characters to upper case
func formatString(s string) string {
	b := []byte(s)
	b = b[1:]

	if b[0] >= 'a' && b[0] <= 'z' {
		b[0] = b[0] - ('a' - 'A')
	}

	return string(b)
}

func removeLastChars(sb *strings.Builder, n int) {
	// Convert the strings.Builder content to a string
	content := sb.String()

	// Slice off the last character
	modifiedContent := content[:len(content)-n]

	// Reset the strings.Builder with the modified string
	sb.Reset()
	sb.WriteString(modifiedContent)
}

func writeToFile(filename string, content string) error {
	// Open the file for writing
	file, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer file.Close()

	_, err = file.WriteString(content)
	if err != nil {
		return err
	}

	return nil
}
