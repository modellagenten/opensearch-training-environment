#!/usr/bin/env python3
"""
OpenSearch Verbindungstest für die Schulungsumgebung
OS-unabhängig: Windows, Linux, macOS
"""

import os
import sys
from pathlib import Path
from opensearchpy import OpenSearch
from dotenv import load_dotenv

def load_environment():
    """
    Lädt die Umgebungsvariablen aus der .env Datei
    Sucht in: ../../.env (übergeordnetes Verzeichnis)
    """
    script_dir = Path(__file__).parent
    env_path = script_dir.parent.parent / '.env';
    
    if env_path.exists():
        load_dotenv(dotenv_path=env_path)
        return str(env_path)
    
    # Keine .env gefunden, verwende Systemumgebungsvariablen
    print("ℹ️  Hinweis: Keine .env Datei gefunden, verwende Systemumgebungsvariablen")
    return None

# Lade Umgebungsvariablen
env_file = load_environment()

def test_opensearch_connection():
    """Testet die Verbindung zu OpenSearch und zeigt Cluster-Status"""
    
    try:
        # Erstelle OpenSearch Client
        client = OpenSearch(
            hosts=[os.environ["OPENSEARCH_HOST"]],
            http_auth=(os.environ["OPENSEARCH_USER"], os.environ["OPENSEARCH_PASSWORD"]),
            use_ssl=True,
            verify_certs=False,
            ssl_assert_hostname=False,
            ssl_show_warn=False
        )
        
        print("🔍 Teste OpenSearch Verbindung...")
        print(f"Host: {os.environ['OPENSEARCH_HOST']}")
        print(f"User: {os.environ['OPENSEARCH_USER']}")
        print("-" * 50)
        
        # Teste Verbindung und hole Cluster-Info
        info = client.info()
        print(f"✅ Verbunden mit OpenSearch")
        print(f"   Version: {info['version']['number']}")
        print(f"   Cluster: {info['cluster_name']}")
        print(f"   Lucene Version: {info['version']['lucene_version']}")
        
        # Hole Cluster Health
        health = client.cluster.health()
        print(f"🔍 Cluster-Zustand: {health['status'].upper()}")
        print(f"   Anzahl Nodes: {health['number_of_nodes']}")
        print(f"   Anzahl Daten-Nodes: {health['number_of_data_nodes']}")
        
        # Teste Index-Liste
        indices = client.cat.indices(format='json')
        print(f"📋 Anzahl Indices: {len(indices)}")
        
        if indices:
            print("   Verfügbare Indices:")
            for idx in indices[:5]:  # Zeige nur die ersten 5
                print(f"     - {idx['index']} ({idx['docs.count']} Dokumente)")
            if len(indices) > 5:
                print(f"     ... und {len(indices) - 5} weitere")
        
        print("\n🎉 OpenSearch Verbindungstest erfolgreich!")
        return True
        
    except Exception as e:
        print(f"❌ Fehler bei OpenSearch Verbindung:")
        print(f"   {str(e)}")
        print("\n💡 Mögliche Lösungen:")
        print("   1. Stellen Sie sicher, dass OpenSearch läuft (docker-compose -f docker-compose-os.yml up)")
        print("   2. Prüfen Sie die .env Datei im Projektverzeichnis")
        print("   3. Prüfen Sie die Netzwerkverbindung")
        print("   4. Warten Sie bis OpenSearch vollständig gestartet ist (kann 1-2 Minuten dauern)")
        return False

def main():
    """Hauptfunktion"""
    print("=" * 60)
    print("OPENSEARCH VERBINDUNGSTEST")
    print(f"Schulungsumgebung - Python ({sys.platform})")
    print("=" * 60)
    
    success = test_opensearch_connection()
    
    if success:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
