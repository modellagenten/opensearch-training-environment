#!/usr/bin/env node

/**
 * Elasticsearch Verbindungstest für die Schulungsumgebung
 * OS-unabhängig: Windows, Linux, macOS
 * 
 * Dieses Programm testet die Verbindung zu Elasticsearch und zeigt
 * grundlegende Cluster-Informationen an.
 */

import { Client } from '@elastic/elasticsearch';
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
 * Erstellt einen Elasticsearch Client mit SSL-Unterstützung
 */
function createElasticsearchClient() {
    const host = process.env.ELASTIC_HOST;
    const user = process.env.ELASTIC_USER;
    const password = process.env.ELASTIC_PASSWORD;
    const verifyCerts = false;

    const client = new Client({
        node: host,
        auth: {
            username: user,
            password: password
        },
        tls: {
            rejectUnauthorized: verifyCerts
        }
    });

    return client;
}

/**
 * Testet die Verbindung zu Elasticsearch und zeigt Cluster-Status
 */
async function testElasticsearchConnection() {
    console.log('='.repeat(60));
    console.log('ELASTICSEARCH VERBINDUNGSTEST');
    console.log(`Schulungsumgebung - JavaScript (${process.platform})`);
    console.log('='.repeat(60));
    
    try {
        // Erstelle Elasticsearch Client
        const client = createElasticsearchClient();
        
        console.log('🔍 Teste Elasticsearch Verbindung...');
        console.log(`Host: ${process.env.ELASTIC_HOST}`);
        console.log(`User: ${process.env.ELASTIC_USER}`);
        console.log('-'.repeat(50));
        
        // Teste Verbindung und hole Cluster-Info
        const info = await client.info();
        console.log('✅ Verbunden mit Elasticsearch');
        console.log(`   Version: ${info.version.number}`);
        console.log(`   Cluster: ${info.cluster_name}`);
        console.log(`   Lucene Version: ${info.version.lucene_version}`);
        
        // Hole Cluster Health
        const health = await client.cluster.health();
        console.log(`🔍 Cluster-Zustand: ${health.status.toUpperCase()}`);
        console.log(`   Anzahl Nodes: ${health.number_of_nodes}`);
        console.log(`   Anzahl Daten-Nodes: ${health.number_of_data_nodes}`);
        
        // Teste Index-Liste
        const indices = await client.cat.indices({ format: 'json' });
        console.log(`📋 Anzahl Indices: ${indices.length}`);
        
        if (indices.length > 0) {
            console.log('   Verfügbare Indices:');
            indices.slice(0, 5).forEach(index => {
                console.log(`     - ${index.index} (${index['docs.count']} Dokumente)`);
            });
            if (indices.length > 5) {
                console.log(`     ... und ${indices.length - 5} weitere`);
            }
        }
        
        console.log('\n🎉 Elasticsearch Verbindungstest erfolgreich!');
        process.exit(0);
        
    } catch (error) {
        console.error('❌ Fehler bei Elasticsearch Verbindung:');
        console.error(`   ${error.message}`);
        console.error('\n💡 Mögliche Lösungen:');
        console.error('   1. Stellen Sie sicher, dass Elasticsearch läuft (docker-compose up)');
        console.error('   2. Prüfen Sie die .env Datei im Projektverzeichnis');
        console.error('   3. Prüfen Sie die Netzwerkverbindung');
        console.error('   4. Warten Sie bis Elasticsearch vollständig gestartet ist');
        
        process.exit(1);
    }
}

// Führe Test aus
testElasticsearchConnection();

