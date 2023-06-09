import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:audioplayers_web/global_audioplayers_web.dart';
import 'package:audioplayers_web/num_extension.dart';
import 'package:audioplayers_web/wrapped_player.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class AudioplayersPlugin with StreamsInterface {
  /// The entrypoint called by the generated plugin registrant.
  static void registerWith(Registrar registrar) {
    AudioplayersPlatformInterface.instance = WebAudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance =
        WebGlobalAudioplayersPlatform();
  }
}

class WebAudioplayersPlatform extends AudioplayersPlatformInterface
    with StreamsInterface {
  // players by playerId
  Map<String, WrappedPlayer> players = {};

  WrappedPlayer getOrCreatePlayer(String playerId) {
    return players.putIfAbsent(playerId, () => WrappedPlayer(playerId, this));
  }

  @override
  Future<int?> getCurrentPosition(String playerId) async {
    final position = getOrCreatePlayer(playerId).player?.currentTime;
    if (position == null) {
      return null;
    }
    return (position * 1000).toInt();
  }

  @override
  Future<int?> getDuration(String playerId) async {
    final jsDuration = getOrCreatePlayer(playerId).player?.duration;
    if (jsDuration == null) {
      return null;
    }
    return jsDuration.fromSecondsToDuration().inMilliseconds;
  }

  @override
  Future<void> pause(String playerId) async {
    getOrCreatePlayer(playerId).pause();
  }

  @override
  Future<void> release(String playerId) async {
    getOrCreatePlayer(playerId).release();
  }

  @override
  Future<void> resume(String playerId) async {
    await getOrCreatePlayer(playerId).resume();
  }

  @override
  Future<void> seek(String playerId, Duration position) async {
    getOrCreatePlayer(playerId).seek(position.inMilliseconds);
  }

  @override
  Future<void> setAudioContext(
    String playerId,
    AudioContext audioContext,
  ) async {
    // no-op: web doesn't have any audio context
  }

  @override
  Future<void> setPlayerMode(
    String playerId,
    PlayerMode playerMode,
  ) async {
    // no-op: web doesn't have multiple modes
  }

  @override
  Future<void> setPlaybackRate(String playerId, double playbackRate) async {
    getOrCreatePlayer(playerId).setPlaybackRate(playbackRate);
  }

  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) async {
    getOrCreatePlayer(playerId).setReleaseMode(releaseMode);
  }

  @override
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    bool? isLocal,
  }) async {
    await getOrCreatePlayer(playerId).setUrl(url);
  }

  @override
  Future<void> setSourceBytes(String playerId, Uint8List bytes) {
    // TODO(luan): implement setSourceBytes for web
    throw UnimplementedError();
  }

  @override
  Future<void> setVolume(String playerId, double volume) async {
    getOrCreatePlayer(playerId).setVolume(volume);
  }

  @override
  Future<void> setBalance(String playerId, double balance) async {
    getOrCreatePlayer(playerId).setBalance(balance);
  }

  @override
  Future<void> stop(String playerId) async {
    getOrCreatePlayer(playerId).stop();
  }
}
