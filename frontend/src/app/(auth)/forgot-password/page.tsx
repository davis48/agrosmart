'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Leaf, Phone, ArrowRight, Home, ArrowLeft } from 'lucide-react'
import { Button, Input, Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui'
import toast from 'react-hot-toast'

const forgotPasswordSchema = z.object({
    telephone: z.string().min(10, 'Numéro de téléphone invalide'),
})

type ForgotPasswordFormData = z.infer<typeof forgotPasswordSchema>

export default function ForgotPasswordPage() {
    const router = useRouter()
    const [isLoading, setIsLoading] = useState(false)

    const {
        register,
        handleSubmit,
        formState: { errors },
    } = useForm<ForgotPasswordFormData>({
        resolver: zodResolver(forgotPasswordSchema),
    })

    const onSubmit = async (data: ForgotPasswordFormData) => {
        setIsLoading(true)
        try {
            // TODO: Implémenter l'appel API pour réinitialiser le mot de passe
            toast.success('Un code de réinitialisation a été envoyé par SMS')
            // Rediriger vers la page de réinitialisation
            // router.push('/reset-password')
        } catch (error) {
            toast.error('Une erreur est survenue')
        } finally {
            setIsLoading(false)
        }
    }

    return (
        <div className="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-green-50 to-green-100 px-4">
            {/* Bouton retour accueil */}
            <Link
                href="/"
                className="absolute top-4 left-4 flex items-center gap-2 text-gray-600 hover:text-green-600 transition-colors"
            >
                <Home className="h-5 w-5" />
                <span className="text-sm font-medium">Accueil</span>
            </Link>

            {/* Logo */}
            <div className="flex items-center gap-2 mb-8">
                <div className="flex h-14 w-14 items-center justify-center rounded-xl bg-green-600 shadow-lg">
                    <Leaf className="h-8 w-8 text-white" />
                </div>
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">AgriTech CI</h1>
                    <p className="text-sm text-gray-500">Surveillance Agricole Intelligente</p>
                </div>
            </div>

            <Card className="w-full max-w-md shadow-xl">
                <CardHeader className="text-center">
                    <CardTitle className="text-2xl">Mot de passe oublié</CardTitle>
                    <CardDescription>
                        Entrez votre numéro de téléphone pour recevoir un code de réinitialisation
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                        <div className="relative">
                            <Phone className="absolute left-3 top-9 h-5 w-5 text-gray-400" />
                            <Input
                                label="Numéro de téléphone"
                                type="tel"
                                placeholder="+225 XX XX XX XX XX"
                                className="pl-10"
                                error={errors.telephone?.message}
                                {...register('telephone')}
                            />
                        </div>

                        <Button
                            type="submit"
                            className="w-full"
                            disabled={isLoading}
                        >
                            {isLoading ? (
                                <span className="flex items-center gap-2">
                                    <span className="animate-spin h-4 w-4 border-2 border-white border-t-transparent rounded-full" />
                                    Envoi en cours...
                                </span>
                            ) : (
                                <span className="flex items-center gap-2">
                                    Envoyer le code
                                    <ArrowRight className="h-4 w-4" />
                                </span>
                            )}
                        </Button>

                        <div className="text-center">
                            <Link
                                href="/login"
                                className="inline-flex items-center gap-2 text-sm text-green-600 hover:text-green-700"
                            >
                                <ArrowLeft className="h-4 w-4" />
                                Retour à la connexion
                            </Link>
                        </div>
                    </form>
                </CardContent>
            </Card>
        </div>
    )
}
