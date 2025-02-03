import 'package:flutter/material.dart';

class CloseMonthButton extends StatelessWidget {
  final VoidCallback onClose;
  final bool mesCerrado;

  const CloseMonthButton({
    super.key,
    required this.onClose,
    required this.mesCerrado,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: mesCerrado ? null : onClose,
      style: ElevatedButton.styleFrom(
        backgroundColor: mesCerrado ? Colors.grey : Colors.orange,
      ),
      child: Text(mesCerrado ? 'Mes Cerrado' : 'Cerrar Mes'),
    );
  }
}

