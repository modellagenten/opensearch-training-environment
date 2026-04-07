package com.example;

import org.opensearch.client.opensearch.OpenSearchClient;
import org.opensearch.client.opensearch.core.InfoResponse;
import org.opensearch.client.opensearch.cluster.HealthResponse;
import org.opensearch.client.opensearch.cat.IndicesResponse;
import org.opensearch.client.opensearch.cat.indices.IndicesRecord;
import org.opensearch.client.transport.OpenSearchTransport;
import org.opensearch.client.transport.httpclient5.ApacheHttpClient5TransportBuilder;
import org.apache.hc.client5.http.auth.AuthScope;
import org.apache.hc.client5.http.auth.UsernamePasswordCredentials;
import org.apache.hc.client5.http.impl.auth.BasicCredentialsProvider;
import org.apache.hc.client5.http.impl.nio.PoolingAsyncClientConnectionManager;
import org.apache.hc.client5.http.impl.nio.PoolingAsyncClientConnectionManagerBuilder;
import org.apache.hc.client5.http.ssl.ClientTlsStrategyBuilder;
import org.apache.hc.core5.function.Factory;
import org.apache.hc.core5.http.HttpHost;
import org.apache.hc.core5.http.nio.ssl.TlsStrategy;
import org.apache.hc.core5.reactor.ssl.TlsDetails;
import org.apache.hc.core5.ssl.SSLContextBuilder;

import io.github.cdimascio.dotenv.Dotenv;

import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLEngine;
import java.net.URL;
import java.util.List;

/**
 * OpenSearch Verbindungstest für die Schulungsumgebung
 * OS-unabhängig: Windows, Linux, macOS
 * 
 * Dieses Programm testet die Verbindung zu OpenSearch und zeigt
 * grundlegende Cluster-Informationen an.
 */
public class OpenSearchConnectionTest {
    
    /**
     * Lädt die Umgebungsvariablen aus der .env Datei
     * Sucht in folgenden Verzeichnissen (in dieser Reihenfolge):
     * 1. ../.env (übergeordnetes Verzeichnis)
     * 2. ./env/.env (Projektverzeichnis)
     * 3. ./.env (aktuelles Verzeichnis)
     * 4. Umgebungsvariablen des Systems
     */
    private static Dotenv loadEnvironment() {
        return Dotenv.configure()
            .directory("..")
            .ignoreIfMissing()
            .load();
    }
    
    public static void main(String[] args) {
        System.out.println("=".repeat(60));
        System.out.println("OPENSEARCH VERBINDUNGSTEST");
        System.out.println("Schulungsumgebung - Java (" + System.getProperty("os.name") + ")");
        System.out.println("=".repeat(60));
        
        // Lade Umgebungsvariablen - suche in verschiedenen Verzeichnissen
        Dotenv dotenv = loadEnvironment();
        
        try {
            // Erstelle OpenSearch Client
            OpenSearchClient client = createOpenSearchClient(dotenv);
            
            System.out.println("  Teste OpenSearch Verbindung...");
            System.out.println("Host: " + dotenv.get("OPENSEARCH_HOST"));
            System.out.println("User: " + dotenv.get("OPENSEARCH_USER"));
            System.out.println("-".repeat(50));
            
            // Teste Verbindung und hole Cluster-Info
            InfoResponse info = client.info();
            System.out.println("  Verbunden mit OpenSearch");
            System.out.println("   Version: " + info.version().number());
            System.out.println("   Cluster: " + info.clusterName());
            System.out.println("   Lucene Version: " + info.version().luceneVersion());
            
            // Hole Cluster Health
            HealthResponse health = client.cluster().health();
            System.out.println("  Cluster-Zustand: " + health.status().toString().toUpperCase());
            System.out.println("   Anzahl Nodes: " + health.numberOfNodes());
            System.out.println("   Anzahl Daten-Nodes: " + health.numberOfDataNodes());
            
            // Teste Index-Liste
            IndicesResponse indicesResponse = client.cat().indices();
            List<IndicesRecord> indices = indicesResponse.valueBody();
            System.out.println("  Anzahl Indices: " + indices.size());
            
            if (!indices.isEmpty()) {
                System.out.println("   Verfügbare Indices:");
                int count = 0;
                for (IndicesRecord index : indices) {
                    if (count >= 5) {
                        System.out.println("     ... und " + (indices.size() - 5) + " weitere");
                        break;
                    }
                    System.out.println("     - " + index.index() + " (" + index.docsCount() + " Dokumente)");
                    count++;
                }
            }
            
            System.out.println("\n  OpenSearch Verbindungstest erfolgreich!");
            
        } catch (Exception e) {
            System.err.println("  Fehler bei OpenSearch Verbindung:");
            System.err.println("   " + e.getMessage());
            System.err.println("\n  Mögliche Lösungen:");
            System.err.println("   1. Stellen Sie sicher, dass OpenSearch läuft (docker-compose -f docker-compose-os.yml up)");
            System.err.println("   2. Prüfen Sie die .env Datei (../.env oder env/.env)");
            System.err.println("   3. Prüfen Sie die Netzwerkverbindung");
            System.err.println("   4. Warten Sie bis OpenSearch vollständig gestartet ist (kann 1-2 Minuten dauern)");
            
            System.exit(1);
        }
    }
    
    /**
     * Erstellt einen OpenSearch Client mit SSL-Unterstützung
     * Basierend auf der aktuellen OpenSearch Java Client Dokumentation
     */
    private static OpenSearchClient createOpenSearchClient(Dotenv dotenv) throws Exception {
        String hostUrl = dotenv.get("OPENSEARCH_HOST");
        URL url = new URL(hostUrl);
        String host = url.getHost();
        int port = url.getPort() == -1 ? (url.getProtocol().equals("https") ? 443 : 80) : url.getPort();
        String scheme = url.getProtocol();
        
        String user = dotenv.get("OPENSEARCH_USER");
        String password = dotenv.get("OPENSEARCH_PASSWORD");
        
        // HttpHost für die Verbindung
        final HttpHost httpHost = new HttpHost(scheme, host, port);
        
        // Credentials Provider
        final BasicCredentialsProvider credentialsProvider = new BasicCredentialsProvider();
        credentialsProvider.setCredentials(
            new AuthScope(httpHost), 
            new UsernamePasswordCredentials(user, password.toCharArray())
        );
        
        // SSL Context (für lokale Entwicklung mit selbstsignierten Zertifikaten)
        final SSLContext sslContext = SSLContextBuilder
            .create()
            .loadTrustMaterial(null, (chains, authType) -> true)
            .build();
        
        // Transport Builder mit Apache HttpClient 5
        final ApacheHttpClient5TransportBuilder builder = ApacheHttpClient5TransportBuilder.builder(httpHost);
        
        builder.setHttpClientConfigCallback(httpClientBuilder -> {
            // TLS-Strategie entsprechend der aktuellen Dokumentation
            final TlsStrategy tlsStrategy = ClientTlsStrategyBuilder.create()
                .setSslContext(sslContext)
                // Siehe https://issues.apache.org/jira/browse/HTTPCLIENT-2219
                .setTlsDetailsFactory(new Factory<SSLEngine, TlsDetails>() {
                    @Override
                    public TlsDetails create(final SSLEngine sslEngine) {
                        return new TlsDetails(sslEngine.getSession(), sslEngine.getApplicationProtocol());
                    }
                })
                .build();
            
            final PoolingAsyncClientConnectionManager connectionManager = PoolingAsyncClientConnectionManagerBuilder
                .create()
                .setTlsStrategy(tlsStrategy)
                .build();
            
            return httpClientBuilder
                .setDefaultCredentialsProvider(credentialsProvider)
                .setConnectionManager(connectionManager);
        });
        
        final OpenSearchTransport transport = builder.build();
        return new OpenSearchClient(transport);
    }
}
