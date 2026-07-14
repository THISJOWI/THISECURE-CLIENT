import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/core/environment_profile_manager.dart';
import 'package:thisjowi/services/token_manager.dart';
import 'package:thisjowi/utils/app_logger.dart';

class MessagingSocketEvent {
  final String type; // 'newMessage', 'readUpdated'
  final Map<String, dynamic> payload;
  MessagingSocketEvent(this.type, this.payload);
}

class MessagingSocketService {
  static final MessagingSocketService _instance = MessagingSocketService._internal();
  factory MessagingSocketService() => _instance;
  MessagingSocketService._internal();

  final TokenManager _tokenManager = TokenManager();

  final StreamController<MessagingSocketEvent> _eventController =
      StreamController<MessagingSocketEvent>.broadcast();

  Stream<MessagingSocketEvent> get events => _eventController.stream;

  final StreamController<Map<String, dynamic>> _messageSentController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageSent => _messageSentController.stream;

  IO.Socket? _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _shouldReconnect = true;
  Timer? _reconnectTimer;
  int _retryCount = 0;

  Future<void> connect() async {
    if (_isConnected) return;
    if (EnvironmentProfileManager().isCloud) return;
    _shouldReconnect = true;
    _retryCount = 0;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    try {
      final token = await _tokenManager.getToken();
      if (token == null || token.isEmpty) {
        appLog.w('MessagingSocket: no token');
        _scheduleReconnect();
        return;
      }

      _socket?.disconnect();
      _socket?.dispose();

      // Connect via gateway with explicit socket.io path.
      // nginx proxies /v1/messages/socket.io/ to the messaging service.
      appLog.i('MessagingSocket: connecting to ${ApiConfig.baseUrl} with path /v1/messages/socket.io');

      _socket = IO.io(
        ApiConfig.baseUrl,
        IO.OptionBuilder()
            .setAuth({'token': token})
            .setPath('/v1/messages/socket.io')
            .build(),
      );

      _socket!.onConnect((_) {
        appLog.i('MessagingSocket: connected');
        _isConnected = true;
        _retryCount = 0;
      });

      _socket!.onDisconnect((_) {
        appLog.i('MessagingSocket: disconnected');
        _isConnected = false;
        if (_shouldReconnect) _scheduleReconnect();
      });

      _socket!.onConnectError((err) {
        appLog.w('MessagingSocket: connect error: $err');
        _isConnected = false;
        if (_shouldReconnect) _scheduleReconnect();
      });

      _socket!.on('newMessage', (data) {
        if (data is Map<String, dynamic>) {
          _eventController.add(MessagingSocketEvent('newMessage', data));
        }
      });

      _socket!.on('readUpdated', (data) {
        if (data is Map<String, dynamic>) {
          _eventController.add(MessagingSocketEvent('readUpdated', data));
        }
      });

      _socket!.on('messageSent', (data) {
        if (data is Map<String, dynamic>) {
          _messageSentController.add(data);
        }
      });

      _socket!.on('error', (data) {
        appLog.w('MessagingSocket: server error: $data');
      });

      _socket!.connect();
    } catch (e) {
      appLog.e('MessagingSocket: error', error: e);
      if (_shouldReconnect) _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    _retryCount++;
    final delay = (_retryCount <= 5 ? _retryCount : 30).clamp(1, 30);
    appLog.d('MessagingSocket: reconnect in ${delay}s');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), _doConnect);
  }

  void emitSendMessage(String conversationId, String text, {String? replyTo, String? ephemeralPublicKey}) {
    if (_socket == null || !_isConnected) return;
    _socket!.emit('sendMessage', {
      'conversationId': conversationId,
      'text': text,
      if (replyTo != null) 'replyTo': replyTo,
      if (ephemeralPublicKey != null) 'ephemeralPublicKey': ephemeralPublicKey,
    });
  }

  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    if (!_eventController.isClosed) _eventController.close();
    if (!_messageSentController.isClosed) _messageSentController.close();
  }
}
