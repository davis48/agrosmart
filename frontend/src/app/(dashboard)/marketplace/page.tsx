'use client'

import { useEffect, useState, useCallback } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import {
  ShoppingCart,
  Plus,
  Search,
  Filter,
  Package,
  User,
  Phone,
  ChevronRight,
  Grid,
  List,
} from 'lucide-react'
import {
  Card,
  CardContent,
  Button,
  Input,
  Badge,
  Skeleton,
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
  Tabs,
  TabsList,
  TabsTrigger,
  TabsContent,
} from '@/components/ui'
import { cn } from '@/lib/utils'
import api from '@/lib/api'
import toast from 'react-hot-toast'

interface Produit {
  id: string
  vendeur_id: string
  nom: string
  description?: string
  categorie: string
  prix: number
  devise: string
  unite: string
  quantite_disponible: number
  images?: string[]
  est_actif: boolean
  vendeur_nom?: string
  vendeur_telephone?: string
  region_nom?: string
  type_offre?: 'vente' | 'location'
  prix_location_jour?: number
  duree_min_location?: number
  caution?: number
}

const categories = [
  { value: 'all', label: 'Toutes les catégories' },
  { value: 'semences', label: 'Semences' },
  { value: 'engrais', label: 'Engrais' },
  { value: 'pesticides', label: 'Pesticides' },
  { value: 'equipements', label: 'Équipements' },
  { value: 'recoltes', label: 'Récoltes' },
  { value: 'services', label: 'Services' },
]

const ProductGrid = ({
  products,
  loading,
  viewMode,
  searchQuery,
  setSearchQuery,
  selectedCategory,
  setSelectedCategory,
  categories,
  setViewMode,
  isRental = false
}: any) => {

  const formatPrice = (prix: number, devise: string) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: devise || 'XOF',
    }).format(prix)
  }

  return (
    <>
      {/* Filters */}
      <div className="flex flex-col md:flex-row gap-4 mb-6">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <Input
            placeholder={isRental ? "Rechercher une location..." : "Rechercher un produit..."}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10"
          />
        </div>
        <Select value={selectedCategory} onValueChange={setSelectedCategory}>
          <SelectTrigger className="w-full md:w-50">
            <Filter className="h-4 w-4 mr-2" />
            <SelectValue placeholder="Catégorie" />
          </SelectTrigger>
          <SelectContent>
            {categories.map((cat: any) => (
              <SelectItem key={cat.value} value={cat.value}>
                {cat.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <div className="flex gap-1 border rounded-lg p-1">
          <Button
            variant={viewMode === 'grid' ? 'default' : 'ghost'}
            size="sm"
            onClick={() => setViewMode('grid')}
          >
            <Grid className="h-4 w-4" />
          </Button>
          <Button
            variant={viewMode === 'list' ? 'default' : 'ghost'}
            size="sm"
            onClick={() => setViewMode('list')}
          >
            <List className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Products grid */}
      {loading ? (
        <div className={cn(
          "grid gap-4",
          viewMode === 'grid' ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3' : 'grid-cols-1'
        )}>
          <Skeleton className="h-64 w-full" />
          <Skeleton className="h-64 w-full" />
          <Skeleton className="h-64 w-full" />
        </div>
      ) : products.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <Package className="h-12 w-12 mx-auto text-gray-300 mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              {searchQuery || selectedCategory !== 'all'
                ? 'Aucun résultat trouvé'
                : isRental ? 'Aucune offre de location disponible' : 'Aucun produit disponible'
              }
            </h3>
            <p className="text-gray-500 mb-4">
              {searchQuery || selectedCategory !== 'all'
                ? 'Essayez avec d\'autres filtres'
                : 'Soyez le premier à publier une annonce!'
              }
            </p>
            <Link href="/marketplace/nouveau">
              <Button>
                <Plus className="h-4 w-4 mr-2" />
                Publier une annonce
              </Button>
            </Link>
          </CardContent>
        </Card>
      ) : viewMode === 'grid' ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {products.map((produit: any) => (
            <Card key={produit.id} className="hover:shadow-md transition-shadow overflow-hidden">
              <div className="relative h-48 bg-gray-100">
                {produit.images && produit.images.length > 0 ? (
                  <Image
                    src={produit.images[0]}
                    alt={produit.nom}
                    fill
                    className="object-cover"
                  />
                ) : (
                  <div className="flex items-center justify-center h-full">
                    <Package className="h-16 w-16 text-gray-300" />
                  </div>
                )}
                <div className="absolute top-2 left-2 flex gap-2">
                  <Badge variant="secondary">
                    {produit.categorie}
                  </Badge>
                  {produit.type_offre === 'location' && (
                    <Badge variant="default" className="bg-blue-600">
                      Location
                    </Badge>
                  )}
                </div>
              </div>
              <CardContent className="p-4">
                <h3 className="font-semibold text-gray-900 mb-1 truncate">
                  {produit.nom}
                </h3>
                <p className="text-sm text-gray-500 mb-3 line-clamp-2">
                  {produit.description || 'Pas de description'}
                </p>
                <div className="flex items-center justify-between mb-3">
                  <p className="text-lg font-bold text-green-600">
                    {produit.type_offre === 'location' ? (
                      <>
                        {formatPrice(produit.prix_location_jour || produit.prix, produit.devise)}
                        <span className="text-sm font-normal text-gray-500">/jour</span>
                      </>
                    ) : (
                      <>
                        {formatPrice(produit.prix, produit.devise)}
                        <span className="text-sm font-normal text-gray-500">/{produit.unite}</span>
                      </>
                    )}

                  </p>
                  <Badge variant="outline">
                    {produit.quantite_disponible} {produit.type_offre === 'location' ? 'dispo' : 'en stock'}
                  </Badge>
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-500 mb-3">
                  <User className="h-4 w-4" />
                  {produit.vendeur_nom || 'Vendeur'}
                </div>
                <Link href={`/marketplace/${produit.id}`}>
                  <Button className="w-full" variant="outline">
                    Voir détails
                    <ChevronRight className="h-4 w-4 ml-2" />
                  </Button>
                </Link>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <div className="space-y-4">
          {products.map((produit: any) => (
            <Card key={produit.id} className="hover:shadow-md transition-shadow">
              <CardContent className="p-4 flex gap-4">
                <div className="relative h-32 w-32 bg-gray-100 rounded-lg shrink-0">
                  {produit.images && produit.images.length > 0 ? (
                    <Image
                      src={produit.images[0]}
                      alt={produit.nom}
                      fill
                      className="object-cover rounded-lg"
                    />
                  ) : (
                    <div className="flex items-center justify-center h-full">
                      <Package className="h-10 w-10 text-gray-300" />
                    </div>
                  )}
                </div>
                <div className="absolute top-2 left-2 flex gap-2">
                  {produit.type_offre === 'location' && (
                    <Badge variant="default" className="bg-blue-600 text-xs">
                      Location
                    </Badge>
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <h3 className="font-semibold text-gray-900 mb-1">
                        {produit.nom}
                      </h3>
                      <Badge variant="secondary" className="mb-2">
                        {produit.categorie}
                      </Badge>
                      <p className="text-sm text-gray-500 line-clamp-2 mb-2">
                        {produit.description || 'Pas de description'}
                      </p>
                    </div>
                    <div className="text-right shrink-0">
                      <p className="text-lg font-bold text-green-600">
                        {produit.type_offre === 'location' ? (
                          <>
                            {formatPrice(produit.prix_location_jour || produit.prix, produit.devise)}
                            <span className="text-sm font-normal text-gray-500">/jour</span>
                          </>
                        ) : (
                          <>
                            {formatPrice(produit.prix, produit.devise)}
                            <span className="text-sm font-normal text-gray-500">/{produit.unite}</span>
                          </>
                        )}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center justify-between mt-2">
                    <div className="flex items-center gap-4 text-sm text-gray-500">
                      <div className="flex items-center gap-1">
                        <User className="h-4 w-4" />
                        {produit.vendeur_nom || 'Vendeur'}
                      </div>
                      {produit.vendeur_telephone && (
                        <div className="flex items-center gap-1">
                          <Phone className="h-4 w-4" />
                          {produit.vendeur_telephone}
                        </div>
                      )}
                    </div>
                    <Link href={`/marketplace/${produit.id}`}>
                      <Button size="sm">
                        Voir détails
                      </Button>
                    </Link>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </>
  )
}

export default function MarketplacePage() {
  const [produits, setProduits] = useState<Produit[]>([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('all')
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid')
  const [activeTab, setActiveTab] = useState<'acheter' | 'vendre'>('acheter')

  const fetchProduits = useCallback(async () => {
    setLoading(true)
    try {
      const response = await api.get('/marketplace/produits')
      if (response.data.success) {
        setProduits(response.data.data || [])
      }
    } catch (error) {
      console.error('Error fetching produits:', error)
      toast.error('Erreur lors du chargement des produits')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchProduits()
  }, [fetchProduits])

  const filteredProduits = produits.filter(p => {
    const matchesSearch = p.nom.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.description?.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesCategory = selectedCategory === 'all' || p.categorie === selectedCategory
    const isActive = p.est_actif !== undefined ? p.est_actif : (p as any).actif !== undefined ? (p as any).actif : true
    return matchesSearch && matchesCategory && isActive
  })

  const formatPrice = (prix: number, devise: string) => {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: devise || 'XOF',
    }).format(prix)
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <ShoppingCart className="h-6 w-6 text-green-600" />
            Marketplace
          </h1>
          <p className="text-gray-500">
            Achetez, vendez et louez des produits et équipements agricoles
          </p>
        </div>
        <Link href="/marketplace/nouveau">
          <Button className="w-full sm:w-auto">
            <Plus className="h-4 w-4 mr-2" />
            Publier une annonce
          </Button>
        </Link>
      </div>

      {/* See below for Tabs section */}


      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as typeof activeTab)}>
        <TabsList className="grid w-full grid-cols-2 max-w-md">
          <TabsTrigger value="acheter">Acheter</TabsTrigger>
          <TabsTrigger value="vendre">Mes annonces</TabsTrigger>
        </TabsList>

        <TabsContent value="acheter" className="mt-6">
          <ProductGrid
            products={filteredProduits}
            loading={loading}
            viewMode={viewMode}
            searchQuery={searchQuery}
            setSearchQuery={setSearchQuery}
            selectedCategory={selectedCategory}
            setSelectedCategory={setSelectedCategory}
            categories={categories}
            setViewMode={setViewMode}
          />
        </TabsContent>

        <TabsContent value="vendre" className="mt-6">
          <Card>
            <CardContent className="py-12 text-center">
              <Package className="h-12 w-12 mx-auto text-gray-300 mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                Mes annonces
              </h3>
              <p className="text-gray-500 mb-4">
                Gérez vos annonces publiées sur le marketplace
              </p>
              <Link href="/marketplace/nouveau">
                <Button>
                  <Plus className="h-4 w-4 mr-2" />
                  Publier une annonce
                </Button>
              </Link>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
