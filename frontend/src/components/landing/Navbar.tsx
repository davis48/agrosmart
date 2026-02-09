'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import { Leaf, ArrowRight } from 'lucide-react'
import { Button } from '@/components/ui/button'

export function Navbar() {
    const [scrolled, setScrolled] = useState(false)

    useEffect(() => {
        const handleScroll = () => {
            setScrolled(window.scrollY > 20)
        }
        window.addEventListener('scroll', handleScroll)
        return () => window.removeEventListener('scroll', handleScroll)
    }, [])

    return (
        <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${scrolled ? 'bg-white/95 backdrop-blur-md shadow-sm border-b border-gray-100' : 'bg-transparent'
            }`}>
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="flex justify-between items-center h-20">
                    <div className="flex items-center gap-3">
                        <div className="h-10 w-10 bg-green-600 rounded-xl flex items-center justify-center shadow-lg shadow-green-600/20">
                            <Leaf className="h-6 w-6 text-white" />
                        </div>
                        <span className={`text-xl font-bold tracking-tight ${scrolled ? 'text-gray-900' : 'text-gray-900'}`}>
                            AgroSmart
                        </span>
                    </div>
                    <div className="hidden md:flex items-center gap-8 font-medium">
                        <a href="#features" className="text-gray-600 hover:text-green-600 transition-colors">Fonctionnalités</a>
                        <a href="#how-it-works" className="text-gray-600 hover:text-green-600 transition-colors">Comment ça marche</a>
                        <a href="#benefits" className="text-gray-600 hover:text-green-600 transition-colors">Avantages</a>
                        <a href="#contact" className="text-gray-600 hover:text-green-600 transition-colors">Contact</a>
                    </div>
                    <div className="flex items-center gap-3">
                        <Link href="/login">
                            <Button variant="ghost" className="font-medium hover:text-green-600 hover:bg-green-50">Connexion</Button>
                        </Link>
                        <Link href="/register">
                            <Button className="bg-green-600 hover:bg-green-700 font-medium shadow-lg shadow-green-600/20 transition-all hover:scale-105">
                                S&apos;inscrire
                                <ArrowRight className="ml-2 h-4 w-4" />
                            </Button>
                        </Link>
                    </div>
                </div>
            </div>
        </nav>
    )
}
