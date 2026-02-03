import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/cart_bloc.dart';
import 'package:intl/intl.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedPaymentMethod = 'mobilemoney';
  String _phoneNumber = '';
  String _deliveryAddress = '';
  String? _deliveryNotes;
  DateTime? _scheduledDeliveryDate;

  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passer la commande'), elevation: 0),
      body: BlocConsumer<CartBloc, CartState>(
        listener: (context, state) {
          if (state is OrderCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Commande passée avec succès!'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/orders');
          } else if (state is CartError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Erreur: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is! CartLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOrderSummaryCard(state),
                  const SizedBox(height: 16),
                  _buildDeliverySection(),
                  const SizedBox(height: 16),
                  _buildPaymentSection(),
                  const SizedBox(height: 24),
                  _buildPlaceOrderButton(context, state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderSummaryCard(CartLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé de la commande',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ...state.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.nom} x${item.quantite}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${(item.prix * item.quantite).toStringAsFixed(0)} FCFA',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sous-total', style: TextStyle(fontSize: 14)),
                Text(
                  '${state.totalPrice.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Frais de livraison',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '${_calculateDeliveryFee(state).toStringAsFixed(0)} FCFA',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(state.totalPrice + _calculateDeliveryFee(state)).toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations de livraison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse de livraison *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une adresse';
                }
                return null;
              },
              onChanged: (value) => _deliveryAddress = value,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Instructions de livraison (optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'Ex: Sonner 2 fois, appeler en arrivant...',
              ),
              maxLines: 2,
              onChanged: (value) =>
                  _deliveryNotes = value.isEmpty ? null : value,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _scheduledDeliveryDate == null
                    ? 'Livraison immédiate'
                    : 'Livraison programmée: ${DateFormat('dd/MM/yyyy').format(_scheduledDeliveryDate!)}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  setState(() => _scheduledDeliveryDate = date);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mode de paiement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              value: 'mobilemoney',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) =>
                  setState(() => _selectedPaymentMethod = value!),
              title: const Row(
                children: [
                  Icon(Icons.phone_android, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Mobile Money'),
                ],
              ),
              subtitle: const Text('Orange Money, MTN, Moov, Wave'),
            ),
            RadioListTile<String>(
              value: 'cash',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) =>
                  setState(() => _selectedPaymentMethod = value!),
              title: const Row(
                children: [
                  Icon(Icons.money, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Paiement à la livraison'),
                ],
              ),
              subtitle: const Text('Payez en espèces lors de la réception'),
            ),
            RadioListTile<String>(
              value: 'card',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) =>
                  setState(() => _selectedPaymentMethod = value!),
              title: const Row(
                children: [
                  Icon(Icons.credit_card, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Carte bancaire'),
                ],
              ),
              subtitle: const Text('Visa, Mastercard'),
            ),
            if (_selectedPaymentMethod == 'mobilemoney') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Numéro Mobile Money *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+225 XX XX XX XX XX',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (_selectedPaymentMethod == 'mobilemoney' &&
                      (value == null || value.isEmpty)) {
                    return 'Veuillez entrer votre numéro';
                  }
                  return null;
                },
                onChanged: (value) => _phoneNumber = value,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceOrderButton(BuildContext context, CartLoaded state) {
    return ElevatedButton(
      onPressed: state is CartProcessing
          ? null
          : () {
              if (_formKey.currentState!.validate()) {
                _showConfirmationDialog(context, state);
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: state is CartProcessing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              'Payer ${(state.totalPrice + _calculateDeliveryFee(state)).toStringAsFixed(0)} FCFA',
            ),
    );
  }

  void _showConfirmationDialog(BuildContext context, CartLoaded state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la commande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${state.items.length} article(s)'),
            Text(
              'Total: ${(state.totalPrice + _calculateDeliveryFee(state)).toStringAsFixed(0)} FCFA',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Paiement: ${_getPaymentMethodLabel()}'),
            Text('Livraison: $_deliveryAddress'),
            if (_scheduledDeliveryDate != null)
              Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(_scheduledDeliveryDate!)}',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CartBloc>().add(
                CheckoutCart(
                  adresseLivraison: _deliveryAddress,
                  methodePaiement: _selectedPaymentMethod,
                  numeroTelephone: _phoneNumber.isEmpty ? null : _phoneNumber,
                  instructions: _deliveryNotes,
                  dateLivraisonProgrammee: _scheduledDeliveryDate,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  double _calculateDeliveryFee(CartLoaded state) {
    // Livraison gratuite au-dessus de 50000 FCFA
    if (state.totalPrice >= 50000) return 0;
    // Sinon 2000 FCFA
    return 2000;
  }

  String _getPaymentMethodLabel() {
    switch (_selectedPaymentMethod) {
      case 'mobilemoney':
        return 'Mobile Money';
      case 'cash':
        return 'Paiement à la livraison';
      case 'card':
        return 'Carte bancaire';
      default:
        return 'Non défini';
    }
  }
}
