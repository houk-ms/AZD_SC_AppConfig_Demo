"use-strict;"
/* eslint-disable @typescript-eslint/no-var-requires */
const dotenv = require("dotenv");
const fs = require("fs");
const os = require("os");

const { DefaultAzureCredential } = require('@azure/identity');
const { SecretClient } = require('@azure/keyvault-secrets');
const { AppConfigurationClient } = require('@azure/app-configuration');

// Retrieve all secrets from Key Vault and set them as environment variables
async function getAllSecrets() {
    try {
        const keyVaultUrl = 'https://kv-64vjiuqrda7la.vault.azure.net/'; // process.env.AZURE_KEY_VAULT_ENDPOINT;
        const credential = new DefaultAzureCredential();
        const secretClient = new SecretClient(keyVaultUrl, credential);
        const secrets = await secretClient.listPropertiesOfSecrets();

        for await (const secretProperties of secrets) {
            const secretName = secretProperties.name;
            const secret = await secretClient.getSecret(secretName);
            process.env[secretName.replace(/-/g, "_")] = secret.value;
            console.log(secretName.replace(/-/g, "_"))
        }
    } catch (error) {
        console.error('Error retrieving secrets:', error.message);
    }
}

// Function to retrieve all key-value pairs from AppConfig and set them as environment variables
async function getAllConfigurations() {
    try {
        const appConfigEndpoint = 'https://appcs-64vjiuqrda7la.azconfig.io'; // process.env.AZURE_APP_CONFIG_ENDPOINT;
        const credential = new DefaultAzureCredential();
        const configClient = new AppConfigurationClient(appConfigEndpoint, credential);
        const configurations = await configClient.listConfigurationSettings();
        for await (const configuration of configurations) {
            const key = configuration.key;
            const value = configuration.value;
            process.env[key] = value;
        }
    } catch (error) {
        console.error('Error retrieving configurations:', error);
    }
}


async function main() {
    await getAllSecrets();
    await getAllConfigurations();

    let envFilePath = ".env"
    let configRoot = "ENV_CONFIG"
    let outputFile = "./public/env-config.js"

    for (let i = 2; i < process.argv.length; i++) {
        switch (process.argv[i]) {
            case "-e":
                envFilePath = process.argv[++i]
            break;
            case "-o":
                outputFile = process.argv[++i]
            break;
            case "-c":
                configRoot = process.argv[++i]
            break;
            default:
                throw Error(`unknown option ${process.argv[i]}`)
        }
    }

    if (fs.existsSync(envFilePath)) {
        console.log(`Loading environment file from '${envFilePath}'`)

        dotenv.config({
            path: envFilePath
        })    
    }

    console.log(`Generating JS configuration output to: ${outputFile}`)

    fs.writeFileSync(outputFile, `window.${configRoot} = {${os.EOL}${
        Object.keys(process.env).filter(x => x.startsWith("REACT_APP_")).map(key => {
            console.log(`- Found '${key}'`);
            return `${key}: '${process.env[key]}',${os.EOL}`;
        }).join("")
    }${os.EOL}}`);
}

main()