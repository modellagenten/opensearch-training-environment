<?php
/**
 * OpenSearch Verbindungstest für die Schulungsumgebung
 * OS-unabhängig: Windows, Linux, macOS
 * 
 * Dieses Skript testet die Verbindung zu OpenSearch und zeigt
 * grundlegende Cluster-Informationen an.
 * 
 * Hinweis: OpenSearch ist kompatibel mit dem Elasticsearch PHP Client,
 * da es die gleiche REST API verwendet.
 */

require_once __DIR__ . '/../install/vendor/autoload.php';

use Elastic\Elasticsearch\ClientBuilder;
use Dotenv\Dotenv;

/**
 * Lädt die Umgebungsvariablen aus der .env Datei
 * Sucht in: ../../.env (übergeordnetes Verzeichnis)
 */
function loadEnvironment(): void {
    $path = __DIR__ . '/../../';
    $envFile = $path . '/.env';
    
    if (file_exists($envFile)) {
        $dotenv = Dotenv::createImmutable($path);
        $dotenv->load();
        return;
    }

    // Keine .env gefunden, Warnung ausgeben
    echo "ℹ️  Hinweis: Keine .env Datei gefunden, verwende Systemumgebungsvariablen\n";
}

// Lade Umgebungsvariablen
loadEnvironment();

function testOpenSearchConnection(): bool
{
    try {
        // Erstelle OpenSearch Client mit Basic Authentication
        // OpenSearch ist kompatibel mit dem Elasticsearch PHP Client
        $client = ClientBuilder::create()
            ->setHosts([$_ENV['OS_HOST']])
            ->setBasicAuthentication($_ENV['OS_USER'], $_ENV['OS_PASSWORD'])
            ->setSSLVerification($_ENV['OS_VERIFY_CERTS'] === 'true')
            ->build();
        
        echo "🔍 Teste OpenSearch Verbindung...\n";
        echo "Host: " . $_ENV['OS_HOST'] . "\n";
        echo "User: " . $_ENV['OS_USER'] . "\n";
        echo str_repeat("-", 50) . "\n";
        
        // Teste Verbindung und hole Cluster-Info
        $response = $client->info();
        $info = $response->asArray();
        
        echo "✅ Verbunden mit OpenSearch\n";
        echo "   Version: " . $info['version']['number'] . "\n";
        echo "   Distribution: " . ($info['version']['distribution'] ?? 'OpenSearch') . "\n";
        echo "   Cluster: " . $info['cluster_name'] . "\n";
        echo "   Lucene Version: " . $info['version']['lucene_version'] . "\n";
        
        // Hole Cluster Health
        $healthResponse = $client->cluster()->health();
        $health = $healthResponse->asArray();
        
        echo "🔍 Cluster-Zustand: " . strtoupper($health['status']) . "\n";
        echo "   Anzahl Nodes: " . $health['number_of_nodes'] . "\n";
        echo "   Anzahl Daten-Nodes: " . $health['number_of_data_nodes'] . "\n";
        
        echo "\n🎉 OpenSearch Verbindungstest erfolgreich!\n";
        return true;
        
    } catch (Exception $e) {
        echo "❌ Fehler bei OpenSearch Verbindung:\n";
        echo "   " . $e->getMessage() . "\n";
        echo "\n💡 Mögliche Lösungen:\n";
        echo "   1. Stellen Sie sicher, dass OpenSearch läuft (docker-compose up)\n";
        echo "   2. Prüfen Sie die .env Datei im env/ Ordner\n";
        echo "   3. Prüfen Sie die Netzwerkverbindung\n";
        echo "   4. Prüfen Sie die SSL-Zertifikat-Einstellungen\n";
        echo "   5. Stellen Sie sicher, dass OpenSearch auf Port 9200 läuft\n";
        return false;
    }
}

function main(): void
{
    echo str_repeat("=", 60) . "\n";
    echo "OPENSEARCH VERBINDUNGSTEST\n";
    echo "Schulungsumgebung - PHP (" . PHP_OS . ")\n";
    echo str_repeat("=", 60) . "\n";
    
    $success = testOpenSearchConnection();
    
    if ($success) {
        exit(0);
    } else {
        exit(1);
    }
}

// Führe das Skript aus
main();
