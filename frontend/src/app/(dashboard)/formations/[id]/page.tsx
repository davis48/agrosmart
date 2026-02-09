'use client'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { formationsApi } from '@/lib/api'
import { Card, CardContent, CardHeader, CardTitle, Progress } from '@/components/ui'
import { ArrowLeft, Clock, BookOpen, CheckCircle2 } from 'lucide-react'
import Link from 'next/link'

export default function FormationDetailPage() {
    const params = useParams()
    const router = useRouter()
    const [formation, setFormation] = useState<any>(null)
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState('')

    useEffect(() => {
        const fetchFormation = async () => {
            try {
                const response = await formationsApi.getById(params.id as string)
                if (response.data.success) {
                    setFormation(response.data.data)
                }
            } catch (err: any) {
                setError(err.response?.data?.message || 'Erreur lors du chargement de la formation')
            } finally {
                setLoading(false)
            }
        }

        if (params.id) {
            fetchFormation()
        }
    }, [params.id])

    if (loading) {
        return (
            <div className="flex items-center justify-center min-h-screen">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600"></div>
            </div>
        )
    }

    if (error || !formation) {
        return (
            <div className="container mx-auto px-4 py-8">
                <Card>
                    <CardContent className="pt-6">
                        <p className="text-red-600 text-center">{error || 'Formation non trouvée'}</p>
                        <div className="flex justify-center mt-4">
                            <Link href="/formations" className="text-green-600 hover:underline flex items-center gap-2">
                                <ArrowLeft className="h-4 w-4" />
                                Retour aux formations
                            </Link>
                        </div>
                    </CardContent>
                </Card>
            </div>
        )
    }

    return (
        <div className="container mx-auto px-4 py-8">
            {/* Header */}
            <div className="mb-6">
                <Link
                    href="/formations"
                    className="inline-flex items-center gap-2 text-gray-600 hover:text-green-600 mb-4"
                >
                    <ArrowLeft className="h-4 w-4" />
                    Retour aux formations
                </Link>

                <h1 className="text-3xl font-bold text-gray-900">{formation.titre}</h1>

                <div className="flex items-center gap-4 mt-4 text-sm text-gray-600">
                    <div className="flex items-center gap-1">
                        <Clock className="h-4 w-4" />
                        <span>{formation.dureeMinutes || 0} minutes</span>
                    </div>
                    <div className="flex items-center gap-1">
                        <BookOpen className="h-4 w-4" />
                        <span>{formation.categorie}</span>
                    </div>
                    <div className="flex items-center gap-1">
                        <span className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full">
                            {formation.niveau}
                        </span>
                    </div>
                </div>
            </div>

            {/* Content */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Main Content */}
                <div className="lg:col-span-2">
                    <Card>
                        <CardHeader>
                            <CardTitle>Description</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-gray-700 whitespace-pre-wrap">
                                {formation.description}
                            </p>

                            {formation.modules && formation.modules.length > 0 && (
                                <div className="mt-6">
                                    <h3 className="text-lg font-semibold mb-4">Modules</h3>
                                    <div className="space-y-3">
                                        {formation.modules.map((module: any, index: number) => (
                                            <div
                                                key={module.id}
                                                className="flex items-start gap-3 p-4 bg-gray-50 rounded-lg"
                                            >
                                                <div className="shrink-0 w-8 h-8 bg-green-600 text-white rounded-full flex items-center justify-center font-semibold">
                                                    {index + 1}
                                                </div>
                                                <div className="flex-1">
                                                    <h4 className="font-medium text-gray-900">{module.titre}</h4>
                                                    {module.contenu && (
                                                        <p className="text-sm text-gray-600 mt-1">
                                                            {module.contenu.substring(0, 150)}
                                                            {module.contenu.length > 150 ? '...' : ''}
                                                        </p>
                                                    )}
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </div>

                {/* Sidebar */}
                <div className="lg:col-span-1">
                    <Card>
                        <CardHeader>
                            <CardTitle>Votre progression</CardTitle>
                        </CardHeader>
                        <CardContent>
                            {formation.progression ? (
                                <>
                                    <div className="mb-4">
                                        <div className="flex justify-between text-sm mb-2">
                                            <span>Progression</span>
                                            <span className="font-semibold">{formation.progression.progression}%</span>
                                        </div>
                                        <Progress
                                            value={formation.progression.progression}
                                            className="h-2 bg-gray-200"
                                            indicatorClassName="bg-green-600"
                                        />
                                    </div>

                                    {formation.progression.complete && (
                                        <div className="flex items-center gap-2 text-green-600 mb-4">
                                            <CheckCircle2 className="h-5 w-5" />
                                            <span className="font-medium">Formation terminée !</span>
                                        </div>
                                    )}

                                    <button
                                        onClick={() => router.push(`/formations/${formation.id}/learn`)}
                                        className="w-full bg-green-600 text-white py-2 px-4 rounded-lg hover:bg-green-700 transition-colors"
                                    >
                                        {formation.progression.progression > 0 ? 'Continuer' : 'Commencer'}
                                    </button>
                                </>
                            ) : (
                                <button
                                    onClick={() => router.push(`/formations/${formation.id}/learn`)}
                                    className="w-full bg-green-600 text-white py-2 px-4 rounded-lg hover:bg-green-700 transition-colors"
                                >
                                    Commencer la formation
                                </button>
                            )}
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    )
}
