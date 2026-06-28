import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../widgets/app_nav.dart';
import '../services/network_data_service.dart';
import '../services/realtime_alert_service.dart';

class ReceiveAlertPage extends StatefulWidget {
  const ReceiveAlertPage({super.key});

  @override
  State<ReceiveAlertPage> createState() => _ReceiveAlertPageState();
}

class _ReceiveAlertPageState extends State<ReceiveAlertPage> {
  late Future<List<Map<String, dynamic>>> _requestsFuture;
  String? _inFlightRequestId;
  final List<Map<String, dynamic>> _liveRequests = <Map<String, dynamic>>[];
  StreamSubscription<Map<String, dynamic>>? _alertsSubscription;

  @override
  void initState() {
    super.initState();
    _requestsFuture = NetworkDataService.getIncomingRequests();
    _startRealtimeAlerts();
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startRealtimeAlerts() async {
    _alertsSubscription =
        RealtimeAlertService.instance.alertsStream.listen((alert) {
      final normalized = _normalizeAlertForInbox(alert);
      if (!mounted) return;

      setState(() {
        _liveRequests.insert(0, normalized);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New incoming request received.')),
      );
    });

    await RealtimeAlertService.instance.connect();
  }

  Map<String, dynamic> _normalizeAlertForInbox(Map<String, dynamic> alert) {
    final requestId = '${alert['request_id'] ?? ''}';
    final alertId = '${alert['alert_id'] ?? ''}';

    return <String, dynamic>{
      ...alert,
      'request_id': requestId,
      'alert_id': alertId,
      'from': alert['requesting_pharmacy_name'] ?? alert['from'] ?? '-',
      'drug': alert['requested_drug'] ?? alert['drug'] ?? '-',
      'qty': alert['required_quantity'] ?? alert['qty'] ?? 0,
      'time': alert['created_at'] ?? alert['time'] ?? '-',
      'status': alert['status'] ?? 'PENDING',
    };
  }

  List<Map<String, dynamic>> _mergeRequests(
    List<Map<String, dynamic>> initialRequests,
  ) {
    final merged = <Map<String, dynamic>>[];
    final seenKeys = <String>{};

    final all = <Map<String, dynamic>>[
      ..._liveRequests,
      ...initialRequests,
    ];

    for (final item in all) {
      final requestKey = '${item['request_id'] ?? ''}';
      final alertKey = '${item['alert_id'] ?? ''}';
      final fallbackKey = '${item['id'] ?? item.hashCode}';
      final dedupeKey =
          requestKey.isNotEmpty ? 'request:$requestKey' : alertKey.isNotEmpty
              ? 'alert:$alertKey'
              : 'fallback:$fallbackKey';

      if (seenKeys.contains(dedupeKey)) {
        continue;
      }

      seenKeys.add(dedupeKey);
      merged.add(item);
    }

    return merged;
  }

  Future<void> _handleDecision(
    Map<String, dynamic> request,
    bool accepted,
  ) async {
    final requestId = '${request['request_id'] ?? request['id'] ?? ''}'.trim();
    if (requestId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request ID is missing.')),
      );
      return;
    }

    setState(() {
      _inFlightRequestId = requestId;
    });

    try {
      await NetworkDataService.respondToIncomingRequest(
        requestId: requestId,
        accepted: accepted,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepted
              ? 'Request accepted and saved.'
              : 'Request declined and saved.'),
        ),
      );

      if (accepted) {
        context.go('/requests/accepted');
        return;
      }

      setState(() {
        _requestsFuture = NetworkDataService.getIncomingRequests();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save decision. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _inFlightRequestId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppNav(links: [
            NavLink(label: 'Dashboard', path: '/dashboard'),
            NavLink(label: 'Requests', path: '/requests', active: true),
          ]),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _requestsFuture,
              builder: (context, snapshot) {
                final requests = _mergeRequests(
                  snapshot.data ?? const <Map<String, dynamic>>[],
                );
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFB4B2A9)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Incoming requests',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A18),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(child: CircularProgressIndicator()),
                        if (snapshot.connectionState != ConnectionState.waiting)
                          ...requests.map((req) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1EFEA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'From: ${req['from'] ?? req['source'] ?? 'Unknown'}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A18),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${req['drug'] ?? req['drug_name'] ?? '-'} • ${req['qty'] ?? req['quantity'] ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF5F5E5A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${req['time'] ?? req['created_at'] ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF5F5E5A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Builder(builder: (context) {
                                          final requestId =
                                              '${req['request_id'] ?? req['id'] ?? ''}';
                                          final isWorking =
                                              _inFlightRequestId == requestId;
                                          return Expanded(
                                            child: ElevatedButton(
                                              onPressed: isWorking
                                                  ? null
                                                  : () => _handleDecision(
                                                        req,
                                                        true,
                                                      ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF1D9E75),
                                                foregroundColor:
                                                    const Color(0xFF04342C),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6),
                                                textStyle: const TextStyle(
                                                    fontSize: 10),
                                              ),
                                              child: Text(isWorking
                                                  ? 'Saving...'
                                                  : 'Accept'),
                                            ),
                                          );
                                        }),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed:
                                                _inFlightRequestId != null
                                                    ? null
                                                    : () => _handleDecision(
                                                          req,
                                                          false,
                                                        ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  const Color(0xFF791F1F),
                                              side: const BorderSide(
                                                  color: Color(0xFF791F1F)),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 6),
                                              textStyle:
                                                  const TextStyle(fontSize: 10),
                                            ),
                                            child: const Text('Decline'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
