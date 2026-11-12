import 'dart:async';

import 'package:flutter/foundation.dart';

class SteamSimulation extends ChangeNotifier {
  Timer? _timer;
  bool _running = false;
  bool _reducerFailed = false;
  double _boilerPressure = 3.2;
  double _boilerOutput = 68;
  double _regulatorSetting = 2.8;
  double _inletValve = 58;
  double _outletValve = 38;
  double _drainValve = 72;
  double _condensateLevel = .24;
  double _heaterTemperature = 34;
  int _elapsedSeconds = 0;

  bool get isRunning => _running;
  bool get reducerFailed => _reducerFailed;
  bool get safetyValveOpen => _boilerPressure >= 6;
  double get boilerPressure => _boilerPressure;
  double get boilerOutput => _boilerOutput;
  double get regulatorSetting => _regulatorSetting;
  double get inletValve => _inletValve;
  double get outletValve => _outletValve;
  double get drainValve => _drainValve;
  double get condensateLevel => _condensateLevel;
  double get heaterTemperature => _heaterTemperature;
  int get elapsedSeconds => _elapsedSeconds;

  double get workingPressure => _reducerFailed
      ? _boilerPressure
      : (_boilerPressure - .2).clamp(0, _regulatorSetting).toDouble();

  double get steamFlow =>
      (_inletValve / 100 * (workingPressure / 3.2) * 100).clamp(0, 100);

  double get steamQuality => (98 - steamFlow * .16).clamp(70, 98);

  double get returnFlow => (_drainValve * _condensateLevel * .92).clamp(0, 100);

  void start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) => _step());
    notifyListeners();
  }

  void pause() {
    if (!_running) return;
    _timer?.cancel();
    _timer = null;
    _running = false;
    notifyListeners();
  }

  void toggle() => _running ? pause() : start();

  void reset() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _reducerFailed = false;
    _boilerPressure = 3.2;
    _boilerOutput = 68;
    _regulatorSetting = 2.8;
    _inletValve = 58;
    _outletValve = 38;
    _drainValve = 72;
    _condensateLevel = .24;
    _heaterTemperature = 34;
    _elapsedSeconds = 0;
    notifyListeners();
  }

  void setReducerFailed(bool value) {
    _reducerFailed = value;
    notifyListeners();
  }

  void setBoilerOutput(double value) => _update(() => _boilerOutput = value);

  void setRegulatorSetting(double value) =>
      _update(() => _regulatorSetting = value);

  void setInletValve(double value) => _update(() => _inletValve = value);

  void setOutletValve(double value) => _update(() => _outletValve = value);

  void setDrainValve(double value) => _update(() => _drainValve = value);

  void _update(VoidCallback update) {
    update();
    notifyListeners();
  }

  void _step() {
    const step = .4;
    final demand = _inletValve / 100 * (workingPressure / 3.2);
    final relief = safetyValveOpen ? .75 : 0.0;
    final pressureChange =
        (_boilerOutput / 100 * .24) - (demand * .13) - .025 - relief;

    _boilerPressure =
        (_boilerPressure + pressureChange * step).clamp(0, 8).toDouble();
    final condensation = (_inletValve / 100) * .075;
    final drainage = (_drainValve / 100) * .055;
    _condensateLevel = (_condensateLevel + (condensation - drainage) * step)
        .clamp(0, 1)
        .toDouble();
    final heat = steamFlow / 100 * (_outletValve / 100) * 18;
    _heaterTemperature =
        (_heaterTemperature + (heat - .045) * step).clamp(18, 110);
    _elapsedSeconds++;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
