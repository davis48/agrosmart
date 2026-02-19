'use client';

import React, { useState } from 'react';
import {
    Users,
    Search,
    Filter,
    MoreVertical,
    UserPlus,
    Edit,
    Trash2,
    Shield,
    CheckCircle,
    XCircle
} from 'lucide-react';
import api from '@/lib/api';
import { logger } from '@/lib/logger';

// Types
interface User {
    id: string;
    name: string;
    email: string;
    role: 'ADMIN' | 'PRODUCTEUR' | 'CONSEILLER';
    status: 'ACTIF' | 'INACTIF';
    cooperative: string;
    lastLogin: string;
}

export default function UsersPage() {
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [searchTerm, setSearchTerm] = useState('');
    const [roleFilter, setRoleFilter] = useState<string>('ALL');


    // Fetch users from API
    React.useEffect(() => {
        async function fetchUsers() {
            try {
                // api.get handles auth headers automatically via interceptors
                const response = await api.get('/users')

                // Données venant de axios sont déjà parsées en JSON dans response.data
                // Le backend renvoie { success: true, data: [...] }
                const usersData = response.data?.data || []

                // Transform API response to match User interface
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                const transformedUsers: User[] = usersData.map((u: any) => ({
                    id: u.id,
                    name: `${u.prenoms || ''} ${u.nom || ''}`.trim(),
                    email: u.email || '-',
                    role: (u.role?.toUpperCase() || 'PRODUCTEUR') as 'ADMIN' | 'PRODUCTEUR' | 'CONSEILLER',
                    status: (u.status === 'actif' ? 'ACTIF' : 'INACTIF') as 'ACTIF' | 'INACTIF',
                    cooperative: u.cooperative?.nom || u.village || '-',
                    lastLogin: (() => {
                        if (!u.derniere_connexion) return 'Jamais'
                        const date = new Date(u.derniere_connexion)
                        return isNaN(date.getTime()) ? 'Jamais' : date.toLocaleString('fr-FR')
                    })()
                }))

                setUsers(transformedUsers);
                setLoading(false);
            } catch (err: any) {
                logger.error('Error fetching admin users', err instanceof Error ? err : undefined);
                const errorMessage = err.response?.data?.message || err.message || 'Erreur inconnue'
                setError(errorMessage);
                setLoading(false);
            }
        }

        fetchUsers();
    }, []);

    // Filtrage
    const filteredUsers = users.filter(user => {
        const matchesSearch = user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
            user.email.toLowerCase().includes(searchTerm.toLowerCase());
        const matchesRole = roleFilter === 'ALL' || user.role === roleFilter;
        return matchesSearch && matchesRole;
    });

    const getRoleColor = (role: string) => {
        switch (role) {
            case 'ADMIN': return 'bg-purple-100 text-purple-800';
            case 'CONSEILLER': return 'bg-blue-100 text-blue-800';
            default: return 'bg-green-100 text-green-800';
        }
    };

    return (
        <div className="p-6 max-w-7xl mx-auto">
            {/* En-tête */}
            <div className="flex justify-between items-center mb-8">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 flex items-center">
                        <Users className="w-8 h-8 mr-3 text-green-600" />
                        Gestion des Utilisateurs
                    </h1>
                    <p className="text-gray-500 mt-1">Gérez les comptes producteurs, conseillers et administrateurs</p>
                </div>
                <button className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg flex items-center transition-colors shadow-sm">
                    <UserPlus className="w-5 h-5 mr-2" />
                    Nouvel Utilisateur
                </button>
            </div>

            {/* Filtres et Recherche */}
            <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100 mb-6 flex flex-col md:flex-row gap-4 justify-between items-center">
                <div className="relative w-full md:w-96">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                    <input
                        type="text"
                        placeholder="Rechercher par nom ou email..."
                        className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-green-500 bg-gray-50"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>

                <div className="flex items-center gap-4 w-full md:w-auto">
                    <div className="flex items-center gap-2">
                        <Filter className="w-5 h-5 text-gray-400" />
                        <span className="text-gray-600 font-medium">Rôle:</span>
                    </div>
                    <select
                        className="border border-gray-200 rounded-lg px-3 py-2 bg-gray-50 focus:outline-none focus:border-green-500"
                        value={roleFilter}
                        onChange={(e) => setRoleFilter(e.target.value)}
                        aria-label="Filtrer par rôle"
                    >
                        <option value="ALL">Tous les rôles</option>
                        <option value="PRODUCTEUR">Producteurs</option>
                        <option value="CONSEILLER">Conseillers</option>
                        <option value="ADMIN">Administrateurs</option>
                    </select>
                    <button className="text-green-600 font-medium hover:underline text-sm ml-2">
                        Export Excel
                    </button>
                </div>
            </div>

            {/* Tableau Utilisateurs */}
            <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                <table className="w-full text-left">
                    <thead className="bg-gray-50 border-b border-gray-100">
                        <tr>
                            <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Utilisateur</th>
                            <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Rôle</th>
                            <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Statut</th>
                            <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Coopérative</th>
                            <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Dernièr cnx</th>
                            <th className="px-6 py-4 text-right text-xs font-semibold text-gray-500 uppercase">Actions</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100">
                        {loading ? (
                            <tr>
                                <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                                    <div className="flex flex-col items-center justify-center">
                                        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600 mb-4"></div>
                                        <p>Chargement des utilisateurs...</p>
                                    </div>
                                </td>
                            </tr>
                        ) : error ? (
                            <tr>
                                <td colSpan={6} className="px-6 py-8 text-center text-red-500">
                                    <p className="font-semibold">Erreur : {error}</p>
                                    <p className="text-sm text-gray-500 mt-2">Veuillez vérifier votre connexion ou réessayer plus tard.</p>
                                </td>
                            </tr>
                        ) : filteredUsers.length > 0 ? (
                            filteredUsers.map((user) => (
                                <tr key={user.id} className="hover:bg-gray-50 transition-colors">
                                    <td className="px-6 py-4">
                                        <div className="flex items-center">
                                            <div className="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center text-green-700 font-bold mr-3">
                                                {user.name.charAt(0)}
                                            </div>
                                            <div>
                                                <div className="font-semibold text-gray-900">{user.name}</div>
                                                <div className="text-sm text-gray-500">{user.email}</div>
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`px-3 py-1 rounded-full text-xs font-semibold ${getRoleColor(user.role)}`}>
                                            {user.role}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4">
                                        <div className="flex items-center">
                                            {user.status === 'ACTIF' ? (
                                                <CheckCircle className="w-4 h-4 text-green-500 mr-2" />
                                            ) : (
                                                <XCircle className="w-4 h-4 text-red-500 mr-2" />
                                            )}
                                            <span className={`text-sm ${user.status === 'ACTIF' ? 'text-green-700' : 'text-red-700'}`}>
                                                {user.status}
                                            </span>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 text-sm text-gray-600">
                                        {user.cooperative}
                                    </td>
                                    <td className="px-6 py-4 text-sm text-gray-500">
                                        {user.lastLogin}
                                    </td>
                                    <td className="px-6 py-4 text-right">
                                        <div className="flex justify-end gap-2">
                                            <button
                                                className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                                                aria-label={`Éditer ${user.name}`}
                                            >
                                                <Edit className="w-4 h-4" />
                                            </button>
                                            <button
                                                className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                                                aria-label={`Supprimer ${user.name}`}
                                            >
                                                <Trash2 className="w-4 h-4" />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))
                        ) : (
                            <tr>
                                <td colSpan={6} className="px-6 py-8 text-center text-gray-500">
                                    Aucun utilisateur trouvé correspondant à votre recherche.
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>

                <div className="bg-gray-50 px-6 py-4 border-t border-gray-100 flex justify-between items-center text-sm text-gray-500">
                    <span>Affichage de {filteredUsers.length} sur {users.length} utilisateurs</span>
                    <div className="flex gap-2">
                        <button className="px-3 py-1 border border-gray-200 rounded hover:bg-white disabled:opacity-50" disabled>Précédent</button>
                        <button className="px-3 py-1 border border-gray-200 rounded hover:bg-white disabled:opacity-50" disabled>Suivant</button>
                    </div>
                </div>
            </div>
        </div>
    );
}
