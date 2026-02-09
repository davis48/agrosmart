import axios, { AxiosInstance, InternalAxiosRequestConfig } from 'axios'

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api/v1'

/**
 * Récupère le token depuis le store Zustand persisté (auth-storage dans localStorage).
 * Centralise l'accès au token pour faciliter une migration future (ex: HttpOnly cookies).
 */
function getPersistedToken(): string | null {
  if (typeof window === 'undefined') return null
  try {
    const raw = localStorage.getItem('auth-storage')
    if (!raw) return null
    const parsed = JSON.parse(raw)
    return parsed?.state?.token ?? null
  } catch {
    return null
  }
}

function clearPersistedAuth(): void {
  if (typeof window === 'undefined') return
  localStorage.removeItem('auth-storage')
}

// Créer l'instance axios
const api: AxiosInstance = axios.create({
  baseURL: API_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Intercepteur pour ajouter le token
api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // Ne pas ajouter le token pour les requêtes d'authentification
    const isAuthRequest = config.url?.includes('/auth/login') ||
      config.url?.includes('/auth/register') ||
      config.url?.includes('/auth/verify-otp');

    if (!isAuthRequest) {
      const token = getPersistedToken()
      if (token && config.headers) {
        config.headers.Authorization = `Bearer ${token}`
      }
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Intercepteur pour gérer les erreurs
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Ne pas rediriger si l'erreur vient de la tentative de connexion elle-même
      const isAuthRequest = error.config?.url?.includes('/auth/login') ||
        error.config?.url?.includes('/auth/verify-otp');

      // Token expiré ou invalide (seulement pour les autres requêtes)
      if (!isAuthRequest && typeof window !== 'undefined') {
        clearPersistedAuth()
        window.location.href = '/login'
      }
    }
    return Promise.reject(error)
  }
)

// ============ AUTH ============
export const authApi = {
  register: (data: {
    telephone: string
    nom: string
    prenoms: string
    password: string
    email?: string
    production_3_mois_precedents_kg?: number
    superficie_exploitee?: number
    unite_superficie?: 'ha' | 'm2'
    region_id?: string
  }) => api.post('/auth/register', { ...data, prenom: data.prenoms }),

  login: (data: { telephone: string; password: string }) =>
    api.post('/auth/login', { identifier: data.telephone, password: data.password }),

  verifyOtp: (data: { telephone: string; otp: string }) =>
    api.post('/auth/verify-otp', { identifier: data.telephone, otp: data.otp }),

  resendOtp: (data: { telephone: string }) =>
    api.post('/auth/resend-otp', data),

  refreshToken: (data: { refreshToken: string }) =>
    api.post('/auth/refresh', data),

  logout: () => api.post('/auth/logout'),
}

// ============ PARCELLES ============
export const parcellesApi = {
  getAll: (params?: { page?: number; limit?: number }) =>
    api.get('/parcelles', { params }),

  getById: (id: string) => api.get(`/parcelles/${id}`),

  create: (data: {
    nom: string
    latitude?: number
    longitude?: number
    superficie_hectares?: number
    type_sol?: string
    description?: string
  }) => api.post('/parcelles', data),

  update: (id: string, data: Partial<{
    nom: string
    latitude: number
    longitude: number
    superficie_hectares: number
    type_sol: string
    description: string
    status: string
  }>) => api.put(`/parcelles/${id}`, data),

  delete: (id: string) => api.delete(`/parcelles/${id}`),

  getStations: (id: string) => api.get(`/parcelles/${id}/stations`),

  getMesures: (id: string) => api.get(`/parcelles/${id}/mesures`),
}

// ============ CULTURES ============
export const culturesApi = {
  getAll: () => api.get('/cultures'),

  getById: (id: string) => api.get(`/cultures/${id}`),
}

// ============ CAPTEURS ============
export const capteursApi = {
  getAll: (params?: { page?: number; limit?: number; type?: string }) =>
    api.get('/capteurs', { params }),

  getById: (id: string) => api.get(`/capteurs/${id}`),

  create: (data: {
    station_id: string
    type: string
    modele?: string
    fabricant?: string
    unite_mesure?: string
  }) => api.post('/capteurs', data),

  update: (id: string, data: Partial<{
    status: string
    modele: string
  }>) => api.put(`/capteurs/${id}`, data),

  delete: (id: string) => api.delete(`/capteurs/${id}`),

  // Stations
  getStations: (params?: { parcelle_id?: string }) =>
    api.get('/capteurs/stations', { params }),

  createStation: (data: {
    nom: string
    parcelle_id: string
    latitude?: number
    longitude?: number
  }) => api.post('/capteurs/stations', data),
}

// ============ MESURES ============
export const mesuresApi = {
  getAll: (params?: {
    capteur_id?: string
    parcelle_id?: string
    start_date?: string
    end_date?: string
    page?: number
    limit?: number
  }) => api.get('/mesures', { params }),

  getLatest: (params?: { parcelle_id?: string }) =>
    api.get('/mesures/latest', { params }),

  create: (data: {
    capteur_id: string
    valeur: number
    qualite_signal?: number
  }) => api.post('/mesures', data),
}

// ============ ALERTES ============
export const alertesApi = {
  getAll: (params?: {
    niveau?: string
    status?: string
    page?: number
    limit?: number
  }) => api.get('/alertes', { params }),

  getById: (id: string) => api.get(`/alertes/${id}`),

  markAsRead: (id: string) => api.put(`/alertes/${id}/read`),

  markAsProcessed: (id: string, data?: { action_prise?: string }) =>
    api.put(`/alertes/${id}/process`, data),

  getUnreadCount: () => api.get('/alertes/unread/count'),
}

// ============ RECOMMANDATIONS ============
export const recommandationsApi = {
  getAll: (params?: {
    type?: string
    parcelle_id?: string
    page?: number
    limit?: number
  }) => api.get('/recommandations', { params }),

  getById: (id: string) => api.get(`/recommandations/${id}`),

  apply: (id: string, data?: { commentaire?: string }) =>
    api.post(`/recommandations/${id}/apply`, data),

  rate: (id: string, data: { note: number; commentaire?: string }) =>
    api.post(`/recommandations/${id}/rate`, data),
}

// ============ MARKETPLACE ============
export const marketplaceApi = {
  // Produits
  getProduits: (params?: {
    categorie?: string
    region_id?: string
    search?: string
    page?: number
    limit?: number
  }) => api.get('/marketplace/produits', { params }),

  getProduitById: (id: string) => api.get(`/marketplace/produits/${id}`),

  createProduit: (data: {
    nom: string
    description?: string
    categorie: string
    prix: number
    unite: string
    quantite_disponible: number
    livraison_possible?: boolean
    frais_livraison?: number
  }) => api.post('/marketplace/produits', data),

  updateProduit: (id: string, data: Partial<{
    nom: string
    description: string
    prix: number
    quantite_disponible: number
    est_actif: boolean
  }>) => api.put(`/marketplace/produits/${id}`, data),

  deleteProduit: (id: string) => api.delete(`/marketplace/produits/${id}`),

  // Commandes
  getCommandes: (params?: { statut?: string }) =>
    api.get('/marketplace/commandes', { params }),

  createCommande: (data: {
    produit_id: string
    quantite: number
    mode_livraison?: string
    adresse_livraison?: string
  }) => api.post('/marketplace/commandes', data),

  updateCommandeStatus: (id: string, data: { statut: string }) =>
    api.put(`/marketplace/commandes/${id}/status`, data),
}

// ============ FORMATIONS ============
export const formationsApi = {
  getAll: (params?: {
    categorie?: string
    langue?: string
    page?: number
    limit?: number
  }) => api.get('/formations', { params }),

  getById: (id: string) => api.get(`/formations/${id}`),

  updateProgress: (id: string, data: { progression: number }) =>
    api.post(`/formations/${id}/progress`, data),

  complete: (id: string, data?: { note?: number }) =>
    api.post(`/formations/${id}/complete`, data),
}

// ============ MESSAGES ============
export const messagesApi = {
  getAll: (params?: {
    destinataire_id?: string
    page?: number
    limit?: number
  }) => api.get('/messages/conversations', { params }),

  getConversation: (userId: string) =>
    api.get(`/messages/conversation/${userId}`),

  send: (data: {
    destinataire_id: string
    contenu: string
    type?: string
  }) => api.post('/messages', data),

  markAsRead: (id: string) => api.put(`/messages/${id}/read`),

  getUnread: () => api.get('/messages/unread'),
}

// ============ STATISTIQUES ============
export const statsApi = {
  getDashboard: () => api.get('/stats/dashboard'),

  getParcelleStats: (id: string, params?: { periode?: string }) =>
    api.get(`/stats/parcelle/${id}`, { params }),

  getROI: (params?: { parcelle_id?: string; periode?: string }) =>
    api.get('/stats/roi', { params }),
}

// ============ FICHES PRATIQUES (Bibliothèque Agricole) ============
export const fichesPratiquesApi = {
  getAll: (params?: { page?: number; limit?: number; categorie?: string }) =>
    api.get('/fiches-pratiques', { params }),

  getById: (id: string) => api.get(`/fiches-pratiques/${id}`),

  search: (params: { q: string; categorie?: string }) =>
    api.get('/fiches-pratiques/search', { params }),

  getCategories: () => api.get('/fiches-pratiques/categories'),

  create: (data: { titre: string; categorie?: string; contenu: string; fichierUrl?: string }) =>
    api.post('/fiches-pratiques', data),

  update: (id: string, data: { titre?: string; categorie?: string; contenu?: string; fichierUrl?: string }) =>
    api.put(`/fiches-pratiques/${id}`, data),

  delete: (id: string) => api.delete(`/fiches-pratiques/${id}`),
}

// ============ STOCKS ============
export const stocksApi = {
  getAll: (params?: { page?: number; limit?: number }) =>
    api.get('/stocks', { params }),

  getById: (id: string) => api.get(`/stocks/${id}`),

  create: (data: { nom: string; categorie?: string; quantite: number; parcelleId?: string; seuilAlerte?: number }) =>
    api.post('/stocks', data),

  update: (id: string, data: Record<string, unknown>) =>
    api.put(`/stocks/${id}`, data),

  delete: (id: string) => api.delete(`/stocks/${id}`),

  getStats: () => api.get('/stocks/statistiques'),

  addMouvement: (id: string, data: { typeMouvement: string; quantite: number; motif?: string }) =>
    api.post(`/stocks/${id}/mouvements`, data),

  getMouvements: (id: string) => api.get(`/stocks/${id}/mouvements`),
}

// ============ CALENDRIER ============
export const calendrierApi = {
  getAll: (params?: { month?: number; year?: number }) =>
    api.get('/calendrier', { params }),

  getById: (id: string) => api.get(`/calendrier/${id}`),

  create: (data: { titre: string; typeActivite: string; dateDebut: string; dateFin?: string; parcelleId?: string; priorite?: string }) =>
    api.post('/calendrier', data),

  update: (id: string, data: Record<string, unknown>) =>
    api.put(`/calendrier/${id}`, data),

  delete: (id: string) => api.delete(`/calendrier/${id}`),

  getProchaines: () => api.get('/calendrier/prochaines'),

  markComplete: (id: string) => api.patch(`/calendrier/${id}/terminer`),

  getStats: () => api.get('/calendrier/statistiques'),
}

// ============ EQUIPMENT ============
export const equipmentApi = {
  getAll: (params?: { page?: number; limit?: number }) =>
    api.get('/equipment/equipment', { params }),

  getById: (id: string) => api.get(`/equipment/equipment/${id}`),

  create: (data: FormData) => api.post('/equipment/equipment', data),

  rent: (id: string, data: { dateDebut: string; dateFin: string }) =>
    api.post(`/equipment/equipment/${id}/rent`, data),

  getMyRentals: () => api.get('/equipment/rentals/my-rentals'),

  getRentalRequests: () => api.get('/equipment/rentals/requests'),

  updateRentalStatus: (id: string, data: { statut: string }) =>
    api.put(`/equipment/rentals/${id}/status`, data),
}

// ============ ANALYTICS (Comparaison saisonnière) ============
export const analyticsApi = {
  getSeasonalComparison: (params?: { annee1?: number; annee2?: number; parcelleId?: string }) =>
    api.get('/analytics/seasonal-comparison', { params }),

  exportData: (params: { format?: string; type?: string }) =>
    api.get('/analytics/export', { params, responseType: params.format === 'csv' ? 'blob' : 'json' }),
}

export default api
