#!/usr/bin/env python3
"""
Elasticsearch Verbindungstest für die Schulungsumgebung
OS-unabhängig: Windows, Linux, macOS
"""

import os
import sys
from pathlib import Path
from elasticsearch import Elasticsearch
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

def test_elasticsearch_connection():
    """Testet die Verbindung zu Elasticsearch und zeigt Cluster-Status"""
    
    try:
        # Erstelle Elasticsearch Client
        es = Elasticsearch(
            os.environ["ELASTIC_HOST"],
            basic_auth=(os.environ["ELASTIC_USER"], os.environ["ELASTIC_PASSWORD"]),
            verify_certs=False,
            ssl_show_warn=False
        )
        
        print("🔍 Teste Elasticsearch Verbindung...")
        print(f"Host: {os.environ['ELASTIC_HOST']}")
        print(f"User: {os.environ['ELASTIC_USER']}")
        print("-" * 50)
        
        # Teste Verbindung und hole Cluster-Info
        info = es.info()
        print(f"✅ Verbunden mit Elasticsearch")
        print(f"   Version: {info['version']['number']}")
        print(f"   Cluster: {info['cluster_name']}")
        print(f"   Lucene Version: {info['version']['lucene_version']}")
        
        # Hole Cluster Health
        health = es.cluster.health()
        print(f"🔍 Cluster-Zustand: {health['status'].upper()}")
        print(f"   Anzahl Nodes: {health['number_of_nodes']}")
        print(f"   Anzahl Daten-Nodes: {health['number_of_data_nodes']}")
        
        # Teste Index-Liste
        indices = es.cat.indices(format='json')
        print(f"📋 Anzahl Indices: {len(indices)}")
        
        if indices:
            print("   Verfügbare Indices:")
            for idx in indices[:5]:  # Zeige nur die ersten 5
                print(f"     - {idx['index']} ({idx['docs.count']} Dokumente)")
            if len(indices) > 5:
                print(f"     ... und {len(indices) - 5} weitere")
        
        print("\n🎉 Elasticsearch Verbindungstest erfolgreich!")
        return True
        
    except Exception as e:
        print(f"❌ Fehler bei Elasticsearch Verbindung:")
        print(f"   {str(e)}")
        print("\n💡 Mögliche Lösungen:")
        print("   1. Stellen Sie sicher, dass Elasticsearch läuft (docker-compose up)")
        print("   2. Prüfen Sie die .env Datei im Projektverzeichnis")
        print("   3. Prüfen Sie die Netzwerkverbindung")
        return False

def main():
    """Hauptfunktion"""
    print("=" * 60)
    print("ELASTICSEARCH VERBINDUNGSTEST")
    print(f"Schulungsumgebung - Python ({sys.platform})")
    print("=" * 60)
    
    success = test_elasticsearch_connection()
    
    if success:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
