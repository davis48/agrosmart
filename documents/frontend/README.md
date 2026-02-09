# 🌐 AgroSmart - Frontend Web

Interface d'administration et dashboard utilisateur.

## 🛠️ Stack Technique

- **Next.js** 14 (App Router)
- **TypeScript**
- **TailwindCSS**
- **Shadcn/UI**

## 🏗️ Architecture

Le frontend utilise Next.js 14 avec App Router pour une architecture moderne et performante :

```mermaid
graph TB
    subgraph Pages["📄 Pages (App Router)"]
        Landing["/(public)/page.tsx<br/>(Landing Page)"]
        Login["/(auth)/login/page.tsx"]
        AdminDash["/(admin)/dashboard/page.tsx"]
        UserDash["/(user)/dashboard/page.tsx"]
        Sensors["/(admin)/sensors/page.tsx"]
        Orders["/(user)/orders/page.tsx"]
    end

    subgraph Components["🧩 Components"]
        Layout["Layout Components<br/>(Header, Sidebar, Footer)"]
        UI["UI Components<br/>(Shadcn/UI)"]
        Charts["Chart Components<br/>(Recharts)"]
        Forms["Form Components"]
    end

    subgraph State["🔄 State Management"]
        Context["React Context<br/>(AuthContext)"]
        LocalStorage["localStorage<br/>(Tokens)"]
    end

    subgraph API["🌐 API Layer"]
        ApiClient["lib/api.ts<br/>(Fetch Wrapper)"]
        Backend["Backend API<br/>(REST)"]
    end

    Pages --> Components
    Pages --> State
    Pages --> ApiClient
    Components --> UI
    ApiClient --> Backend
    State --> LocalStorage

    style Landing fill:#4CAF50
    style AdminDash fill:#FF9800
    style UserDash fill:#2196F3
    style UI fill:#9C27B0
    style Backend fill:#F44336
```

## 🐳 Docker (Recommandé)

Le frontend fait partie de la stack Docker Compose. Pour démarrer tous les services :

```bash
# Depuis la racine du projet
docker-compose up -d

# Voir les logs du frontend
docker-compose logs -f frontend

# Redémarrer le frontend uniquement
docker-compose restart frontend

# Rebuild après modifications
docker-compose up -d --build frontend

# Accéder au shell du container
docker-compose exec frontend sh
```

### URL d'accès

- **Frontend Web** : <http://localhost:3001>
- **Backend API** : <http://localhost:3000>

## 🚀 Développement Local (Sans Docker)

```bash
# Installation
npm install

# Démarrage (Dev)
npm run dev
# URL: http://localhost:3001

# Build (Prod)
npm run build
npm start
```

## 📁 Structure

- `app/` : Pages et routing (Next.js App Router)
- `components/` : Composants UI réutilisables
- `lib/` : Utilitaires et clients API
