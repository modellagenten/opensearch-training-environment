#!/usr/bin/env node

/**
 * OpenSearch Verbindungstest für die Schulungsumgebung
 * OS-unabhängig: Windows, Linux, macOS
 * 
 * Dieses Programm testet die Verbindung zu OpenSearch und zeigt
 * grundlegende Cluster-Informationen an.
 */

import { Client } from '@opensearch-project/opensearch';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import { existsSync } from 'fs';

// ES Module __dirname equivalent
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Lädt die Umgebungsvariablen aus der .env Datei
 * Sucht in: ../../.env (übergeordnetes Verzeichnis)
 */
function loadEnvironment() {
    const envPath = path.join(__dirname, '..', '..', '.env');

    if (existsSync(envPath)) {
        dotenv.config({ path: envPath });
        return envPath;
    }

    // Keine .env gefunden, verwende Systemumgebungsvariablen
    console.log('ℹ️  Hinweis: Keine .env Datei gefunden, verwende Systemumgebungsvariablen');
    return null;
}

// Lade Umgebungsvariablen
const envPath = loadEnvironment();

/**
 * Erstellt einen OpenSearch Client mit SSL-Unterstützung
 */
function createOpenSearchClient() {
    const host = process.env.OPENSEARCH_HOST;
    const user = process.env.OPENSEARCH_USER;
    const password = process.env.OPENSEARCH_PASSWORD;
    const verifyCerts = false;

    const client = new Client({
        node: host,
        auth: {
            username: user,
            password: password
        },
        ssl: {
            rejectUnauthorized: verifyCerts
        }
    });

    return client;
}

/**
 * Testet die Verbindung zu OpenSearch und zeigt Cluster-Status
 */
async function testOpenSearchConnection() {
    console.log('='.repeat(60));
    console.log('OPENSEARCH VERBINDUNGSTEST');
    console.log(`Schulungsumgebung - JavaScript (${process.platform})`);
    console.log('='.repeat(60));
    
    try {
        // Erstelle OpenSearch Client
        const client = createOpenSearchClient();
        
        console.log('🔍 Teste OpenSearch Verbindung...');
        console.log(`Host: ${process.env.OPENSEARCH_HOST}`);
        console.log(`User: ${process.env.OPENSEARCH_USER}`);
        console.log('-'.repeat(50));
        
        // Teste Verbindung und hole Cluster-Info
        const info = await client.info();
        console.log('✅ Verbunden mit OpenSearch');
        console.log(`   Version: ${info.body.version.number}`);
        console.log(`   Cluster: ${info.body.cluster_name}`);
        console.log(`   Lucene Version: ${info.body.version.lucene_version}`);
        
        // Hole Cluster Health
        const health = await client.cluster.health();
        console.log(`🔍 Cluster-Zustand: ${health.body.status.toUpperCase()}`);
        console.log(`   Anzahl Nodes: ${health.body.number_of_nodes}`);
        console.log(`   Anzahl Daten-Nodes: ${health.body.number_of_data_nodes}`);
        
        // Teste Index-Liste
        const indices = await client.cat.indices({ format: 'json' });
        console.log(`📋 Anzahl Indices: ${indices.body.length}`);
        
        if (indices.body.length > 0) {
            console.log('   Verfügbare Indices:');
            indices.body.slice(0, 5).forEach(index => {
                console.log(`     - ${index.index} (${index['docs.count']} Dokumente)`);
            });
            if (indices.body.length > 5) {
                console.log(`     ... und ${indices.body.length - 5} weitere`);
            }
        }
        
        console.log('\n🎉 OpenSearch Verbindungstest erfolgreich!');
        process.exit(0);
        
    } catch (error) {
        console.error('❌ Fehler bei OpenSearch Verbindung:');
        console.error(`   ${error.message}`);
        console.error('\n💡 Mögliche Lösungen:');
        console.error('   1. Stellen Sie sicher, dass OpenSearch läuft (docker-compose -f docker-compose-os.yml up)');
        console.error('   2. Prüfen Sie die .env Datei im Projektverzeichnis');
        console.error('   3. Prüfen Sie die Netzwerkverbindung');
        console.error('   4. Warten Sie bis OpenSearch vollständig gestartet ist (kann 1-2 Minuten dauern)');
        
        process.exit(1);
    }
}

// Führe Test aus
testOpenSearchConnection();

