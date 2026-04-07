package com.example;

import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.elasticsearch.core.InfoResponse;
import co.elastic.clients.elasticsearch.cluster.HealthResponse;
import co.elastic.clients.elasticsearch.cat.IndicesResponse;
import co.elastic.clients.elasticsearch.cat.indices.IndicesRecord;
import co.elastic.clients.transport.TransportUtils;
import io.github.cdimascio.dotenv.Dotenv;

import javax.net.ssl.SSLContext;
import org.apache.hc.core5.ssl.SSLContextBuilder;

/**
 * Elasticsearch Verbindungstest für die Schulungsumgebung
 * OS-unabhängig: Windows, Linux, macOS
 * 
 * Dieses Programm testet die Verbindung zu Elasticsearch und zeigt
 * grundlegende Cluster-Informationen an.
 */
public class ElasticsearchConnectionTest {
    
    /**
     * Lädt die Umgebungsvariablen aus der .env Datei
     * Sucht in: ../../.env (übergeordnetes Verzeichnis)
     */
    private static Dotenv loadEnvironment() {
        return Dotenv.configure()
            .directory("..")
            .ignoreIfMissing()
            .load();
    }
    
    public static void main(String[] args) {
        System.out.println("=".repeat(60));
        System.out.println("ELASTICSEARCH VERBINDUNGSTEST");
        System.out.println("Schulungsumgebung - Java (" + System.getProperty("os.name") + ")");
        System.out.println("=".repeat(60));
        
        // Lade Umgebungsvariablen - suche in verschiedenen Verzeichnissen
        Dotenv dotenv = loadEnvironment();
        
        try (ElasticsearchClient client = createElasticsearchClient(dotenv)) {
            System.out.println("Teste Elasticsearch Verbindung...");
            System.out.println("Host: " + dotenv.get("ELASTIC_HOST"));
            System.out.println("User: " + dotenv.get("ELASTIC_USER"));
            System.out.println("-".repeat(50));
            
            // Teste Verbindung und hole Cluster-Info
            InfoResponse info = client.info();
            System.out.println("   Verbunden mit Elasticsearch");
            System.out.println("   Version: " + info.version().number());
            System.out.println("   Cluster: " + info.clusterName());
            System.out.println("   Lucene Version: " + info.version().luceneVersion());
            
            // Hole Cluster Health
            HealthResponse health = client.cluster().health();
            System.out.println("   Cluster-Zustand: " + health.status().toString().toUpperCase());
            System.out.println("   Anzahl Nodes: " + health.numberOfNodes());
            System.out.println("   Anzahl Daten-Nodes: " + health.numberOfDataNodes());
            
            // Teste Index-Liste
            
            System.out.println("\n  Elasticsearch Verbindungstest erfolgreich!");
            
        } catch (Exception e) {
            System.err.println("  Fehler bei Elasticsearch Verbindung:");
            System.err.println("   " + e.getMessage());
            System.err.println("\n  Mögliche Lösungen:");
            System.err.println("   1. Stellen Sie sicher, dass Elasticsearch läuft (docker-compose up)");
            System.err.println("   2. Prüfen Sie die .env Datei (../.env oder env/.env)");
            System.err.println("   3. Prüfen Sie die Netzwerkverbindung");
            System.err.println("   4. Warten Sie bis Elasticsearch vollständig gestartet ist");
            
            System.exit(1);
        }
    }
    
    /**
     * Erstellt einen Elasticsearch Client mit SSL-Unterstützung
     * Basierend auf der offiziellen Elasticsearch Java Client Dokumentation
     */
    private static ElasticsearchClient createElasticsearchClient(Dotenv dotenv) throws Exception {
        String serverUrl = dotenv.get("ELASTIC_HOST");
        String username = dotenv.get("ELASTIC_USER");
        String password = dotenv.get("ELASTIC_PASSWORD");
        
        // SSL Context für lokale Entwicklung (selbstsignierte Zertifikate)
        // In Produktion sollte ein gültiges Zertifikat verwendet werden
        SSLContext sslContext = SSLContextBuilder
        .create()
        .loadTrustMaterial(null, (chains, authType) -> true)
        .build();
        
        // Erstelle Client mit moderner API (entspricht offizieller Dokumentation)
        return ElasticsearchClient.of(b -> b
            .host(serverUrl)
            .usernameAndPassword(username, password)
            .sslContext(sslContext)
        );
    }
}
