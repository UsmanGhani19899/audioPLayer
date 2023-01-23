import 'dart:async';

// TODO(gustl22): remove when upgrading min Flutter version to >=3.3.0
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:audioplayers_platform_interface/api/audio_context_config.dart';
import 'package:audioplayers_platform_interface/api/global_event.dart';
import 'package:audioplayers_platform_interface/api/player_event.dart';
import 'package:audioplayers_platform_interface/api/player_mode.dart';
import 'package:audioplayers_platform_interface/api/release_mode.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:audioplayers_platform_interface/method_channel_interface.dart';
import 'package:audioplayers_platform_interface/streams_interface.dart';
import 'package:flutter/services.dart';

class MethodChannelAudioplayersPlatform extends AudioplayersPlatform
    with StreamsInterface {
  final MethodChannel _channel = const MethodChannel('xyz.luan/audioplayers');

  MethodChannelAudioplayersPlatform() {
    _channel.setMethodCallHandler(platformCallHandler);
  }

  @override
  Future<int?> getCurrentPosition(String playerId) {
    return _compute('getCurrentPosition', playerId);
  }

  @override
  Future<int?> getDuration(String playerId) {
    return _compute('getDuration', playerId);
  }

  @override
  Future<void> pause(String playerId) {
    return _call('pause', playerId);
  }

  @override
  Future<void> release(String playerId) {
    return _call('release', playerId);
  }

  @override
  Future<void> resume(String playerId) {
    return _call('resume', playerId);
  }

  @override
  Future<void> seek(String playerId, Duration position) {
    return _call(
      'seek',
      playerId,
      <String, dynamic>{
        'position': position.inMilliseconds,
      },
    );
  }

  @override
  Future<void> setAudioContext(
    String playerId,
    AudioContext context,
  ) {
    return _call(
      'setAudioContext',
      playerId,
      context.toJson(),
    );
  }

  @override
  Future<void> setBalance(
    String playerId,
    double balance,
  ) {
    return _call(
      'setBalance',
      playerId,
      <String, dynamic>{'balance': balance},
    );
  }

  @override
  Future<void> setPlayerMode(
    String playerId,
    PlayerMode playerMode,
  ) {
    return _call(
      'setPlayerMode',
      playerId,
      <String, dynamic>{
        'playerMode': playerMode.toString(),
      },
    );
  }

  @override
  Future<void> setPlaybackRate(String playerId, double playbackRate) {
    return _call(
      'setPlaybackRate',
      playerId,
      <String, dynamic>{'playbackRate': playbackRate},
    );
  }

  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) {
    return _call(
      'setReleaseMode',
      playerId,
      <String, dynamic>{
        'releaseMode': releaseMode.toString(),
      },
    );
  }

  @override
  Future<void> setSourceBytes(String playerId, Uint8List bytes) {
    return _call(
      'setSourceBytes',
      playerId,
      <String, dynamic>{
        'bytes': bytes,
      },
    );
  }

  @override
  Future<void> setSourceUrl(String playerId, String url, {bool? isLocal}) {
    return _call(
      'setSourceUrl',
      playerId,
      <String, dynamic>{
        'url': url,
        'isLocal': isLocal,
      },
    );
  }

  @override
  Future<void> setVolume(String playerId, double volume) {
    return _call(
      'setVolume',
      playerId,
      <String, dynamic>{
        'volume': volume,
      },
    );
  }

  @override
  Future<void> stop(String playerId) {
    return _call('stop', playerId);
  }

  @override
  Stream<PlayerEvent> getEventStream(String playerId) {
    return _eventChannelFor(playerId);
  }

  @override
  Stream<GlobalEvent> getGlobalEventStream() {
    return _globalEventChannel();
  }

  Future<void> platformCallHandler(MethodCall call) async {
    try {
      _doHandlePlatformCall(call);
    } on Exception catch (ex) {
      // TODO should be replaced anyways
    }
  }

  // TODO replace with event stream
  void _doHandlePlatformCall(MethodCall call) {
    if (call.containsKey('playerId')) {
      final playerId = call.getString('playerId');
      switch (call.method) {
        case 'audio.onDuration':
          final millis = call.getInt('value');
          final duration = Duration(milliseconds: millis);
          emitDuration(playerId, duration);
          break;
        case 'audio.onCurrentPosition':
          final millis = call.getInt('value');
          final position = Duration(milliseconds: millis);
          emitPosition(playerId, position);
          break;
        case 'audio.onComplete':
          emitComplete(playerId);
          break;
        case 'audio.onSeekComplete':
          emitSeekComplete(playerId);
          break;
        default:
        // TODO throw UnimplementedError
      }
    }
  }

  Stream<PlayerEvent> _eventChannelFor(String playerId) {
    final eventChannel = EventChannel('xyz.luan/audioplayers/events/$playerId');

    return eventChannel.receiveBroadcastStream().map(
      (dynamic event) {
        final map = event as Map<dynamic, dynamic>;
        final eventType = map.getString('event');
        switch (eventType) {
          case 'audio.onLog':
            final value = map.getString('value');
            return PlayerEvent(
                eventType: PlayerEventType.log, logMessage: value);
          default:
            throw UnimplementedError('Event Method does not exist $eventType');
        }
      },
    );
  }

  Stream<GlobalEvent> _globalEventChannel() {
    const globalEventChannel =
        EventChannel('xyz.luan/audioplayers.global/events');
    return globalEventChannel.receiveBroadcastStream().map((dynamic event) {
      final map = event as Map<dynamic, dynamic>;
      final eventType = map.getString('event');
      switch (eventType) {
        case 'audio.onGlobalLog':
          final value = map.getString('value');
          return GlobalEvent(eventType: GlobalEventType.log, logMessage: value);
        default:
          throw UnimplementedError(
            'Global Event Method does not exist $eventType',
          );
      }
    });
  }

  Future<void> _call(
    String method,
    String playerId, [
    Map<String, dynamic> arguments = const <String, dynamic>{},
  ]) async {
    final enhancedArgs = <String, dynamic>{
      'playerId': playerId,
      ...arguments,
    };
    return _channel.call(method, enhancedArgs);
  }

  Future<T?> _compute<T>(
    String method,
    String playerId, [
    Map<String, dynamic> arguments = const <String, dynamic>{},
  ]) async {
    final enhancedArgs = <String, dynamic>{
      'playerId': playerId,
      ...arguments,
    };
    return _channel.compute<T>(method, enhancedArgs);
  }
}
