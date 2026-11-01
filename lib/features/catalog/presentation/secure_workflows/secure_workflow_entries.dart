part of '../secure_workflow_screens.dart';

class BrokerConnectionScreen extends StatefulWidget {
  const BrokerConnectionScreen({super.key, required this.apiClient});
  final ApiGateway apiClient;

  @override
  State<BrokerConnectionScreen> createState() => _BrokerConnectionScreenState();
}

class CopyTradeDashboardScreen extends StatefulWidget {
  const CopyTradeDashboardScreen({super.key, required this.apiClient});

  final ApiGateway apiClient;

  @override
  State<CopyTradeDashboardScreen> createState() =>
      _CopyTradeDashboardScreenState();
}

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({
    super.key,
    required this.apiClient,
    this.productUuid,
  });
  final ApiGateway apiClient;
  final String? productUuid;

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}
