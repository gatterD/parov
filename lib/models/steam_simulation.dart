import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

class SteamSimulation extends ChangeNotifier {
  static const double boilerVolumeM3 = 1.2;
  static const double boilerSteamSpaceM3 = 0.85;
  static const double nominalBoilerPressureBar = 3.2;
  static const double maximumBoilerPressureBar = 8.0;
  static const double maximumBoilerThermalPowerKw = 220.0;
  static const double ambientTemperatureC = 18.0;
  static const double distributionCapacityKgPerHour = 420.0;
  static const double condensateBoxCapacityKg = 250.0;
  static const double warmTankCapacityKg = 600.0;

  static const double _atmosphericPressureBar = 1.01325;
  static const double _steamGasConstantKjPerKgK = 0.4615;
  static const double _boilerSteamTemperatureKelvin = 423.15;
  static const double _latentHeatKjPerKg = 2257.0;
  static const double _regulatorMinimumDifferentialBar = 0.15;
  static const double _regulatorReferenceDifferentialBar = 0.4;
  static const double _regulatorCapacityKgPerHour = 420.0;
  static const double _safetyValveOpeningPressureBar = 6.0;
  static const double _safetyValveClosingPressureBar = 5.7;
  static const double _safetyValveCapacityKgPerHour = 700.0;
  static const double _heaterThermalCapacityKjPerC = 4500.0;
  static const double _heaterHeatLossKwPerC = 0.8;
  static const double _heaterHeatTransferEfficiency = 0.82;
  static const double _heaterCondensateCapacityKg = 80.0;
  static const double _heaterOutletCapacityKgPerHour = 260.0;
  static const double _condensateTrapCapacityKgPerHour = 220.0;
  static const Duration _timerInterval = Duration(milliseconds: 100);
  static const double _maximumIntegrationStepSeconds = 0.1;

  final Stopwatch _clock = Stopwatch();
  Timer? _timer;
  bool _running = false;
  bool _reducerFailed = false;
  bool _safetyValveOpen = false;
  double _boilerOutput = 68;
  double _regulatorSetting = 2.8;
  double _inletValve = 58;
  double _outletValve = 38;
  double _drainValve = 72;
  double _boilerSteamMassKg = 0;
  double _heaterCondensateMassKg = 0;
  double _condensateMassKg = 0;
  double _warmTankMassKg = 0;
  double _heaterTemperature = 34;
  double _heaterDrainRateKgPerHour = 0;
  double _trapFlowRateKgPerHour = 0;
  double _condensateSpilledKg = 0;
  double _simulatedSeconds = 0;
  Duration _lastClockElapsed = Duration.zero;

  SteamSimulation() {
    _boilerSteamMassKg = _steamMassAtGaugePressure(nominalBoilerPressureBar);
    _condensateMassKg = condensateBoxCapacityKg * 0.24;
  }

  bool get isRunning => _running;
  bool get reducerFailed => _reducerFailed;
  bool get safetyValveOpen => _safetyValveOpen;
  bool get boilerOverpressure => boilerPressure >= maximumBoilerPressureBar;
  bool get downstreamOverpressure => workingPressure > 4.5;
  bool get condensateOverflow => _condensateSpilledKg > 0;
  bool get emergencyState =>
      _reducerFailed ||
      _safetyValveOpen ||
      boilerOverpressure ||
      downstreamOverpressure ||
      condensateOverflow;

  double get boilerPressure => _boilerPressureFromMass(_boilerSteamMassKg);
  double get boilerOutput => _boilerOutput;
  double get boilerThermalPowerKw =>
      maximumBoilerThermalPowerKw * _boilerOutput / 100;
  double get steamProductionKgPerHour =>
      boilerThermalPowerKw * 3600 / _latentHeatKjPerKg;
  double get regulatorSetting => _regulatorSetting;
  double get regulatorPosition {
    if (_reducerFailed) return 100;
    final pressureDrop = boilerPressure - workingPressure;
    final availableCapacity = _regulatorCapacityKgPerHour *
        math.sqrt(
          math.max(pressureDrop, _regulatorMinimumDifferentialBar) /
              _regulatorReferenceDifferentialBar,
        );
    return (steamFlowKgPerHour / availableCapacity * 100)
        .clamp(0, 100)
        .toDouble();
  }

  double get inletValve => _inletValve;
  double get outletValve => _outletValve;
  double get drainValve => _drainValve;
  double get condensateLevel =>
      (_condensateMassKg / condensateBoxCapacityKg).clamp(0, 1).toDouble();
  double get heaterCondensateLevel =>
      (_heaterCondensateMassKg / _heaterCondensateCapacityKg)
          .clamp(0, 1)
          .toDouble();
  double get warmTankLevel =>
      (_warmTankMassKg / warmTankCapacityKg).clamp(0, 1).toDouble();
  double get warmTankMassKg => _warmTankMassKg;
  double get heaterTemperature => _heaterTemperature;
  int get elapsedSeconds => _simulatedSeconds.floor();

  double get workingPressure {
    if (_reducerFailed) return boilerPressure;
    return math
        .min(
          _regulatorSetting,
          boilerPressure - _regulatorMinimumDifferentialBar,
        )
        .clamp(0, _regulatorSetting)
        .toDouble();
  }

  double get steamFlowKgPerHour {
    if (_inletValve <= 0 || workingPressure <= 0) return 0;
    final pressureRatio = workingPressure / _regulatorSetting;
    return (distributionCapacityKgPerHour *
            _inletValve /
            100 *
            math.sqrt(pressureRatio))
        .clamp(0, distributionCapacityKgPerHour)
        .toDouble();
  }

  double get steamFlow =>
      (steamFlowKgPerHour / distributionCapacityKgPerHour * 100)
          .clamp(0, 100)
          .toDouble();

  double get separatorInletWetness {
    final load = steamFlowKgPerHour / distributionCapacityKgPerHour;
    return (0.02 + 0.10 * load * load).clamp(0.02, 0.25).toDouble();
  }

  double get separatorInletQuality =>
      (100 * (1 - separatorInletWetness)).clamp(0, 100).toDouble();

  double get separatorEfficiency {
    final load = steamFlowKgPerHour / distributionCapacityKgPerHour;
    return (0.96 - 0.16 * load * load).clamp(0.70, 0.96).toDouble();
  }

  double get steamQuality =>
      (100 * (1 - separatorInletWetness * (1 - separatorEfficiency)))
          .clamp(0, 100)
          .toDouble();

  double get heaterSteamFlowKgPerHour => steamFlowKgPerHour;
  double get heaterThermalPowerKw =>
      heaterSteamFlowKgPerHour /
      3600 *
      _latentHeatKjPerKg *
      _heaterHeatTransferEfficiency *
      (_outletValve / 100) *
      (steamQuality / 100);
  double get condensateProductionKgPerHour =>
      heaterThermalPowerKw * 3600 / _latentHeatKjPerKg;
  double get heaterDrainFlowKgPerHour => _heaterDrainRateKgPerHour;
  double get returnFlowKgPerHour => _trapFlowRateKgPerHour;
  double get safetyValveDischargeKgPerHour => _safetyValveDischargeKgPerHour;
  double get returnFlow =>
      (_trapFlowRateKgPerHour / _condensateTrapCapacityKgPerHour * 100)
          .clamp(0, 100)
          .toDouble();

  void start() {
    if (_running) return;
    _running = true;
    _clock.start();
    _lastClockElapsed = _clock.elapsed;
    _timer = Timer.periodic(_timerInterval, (_) => _step());
    notifyListeners();
  }

  void pause() {
    if (!_running) return;
    _step();
    _timer?.cancel();
    _timer = null;
    _clock.stop();
    _running = false;
    notifyListeners();
  }

  void toggle() => _running ? pause() : start();

  void reset() {
    _timer?.cancel();
    _timer = null;
    _clock
      ..stop()
      ..reset();
    _running = false;
    _reducerFailed = false;
    _safetyValveOpen = false;
    _boilerOutput = 68;
    _regulatorSetting = 2.8;
    _inletValve = 58;
    _outletValve = 38;
    _drainValve = 72;
    _boilerSteamMassKg = _steamMassAtGaugePressure(nominalBoilerPressureBar);
    _heaterCondensateMassKg = 0;
    _condensateMassKg = condensateBoxCapacityKg * 0.24;
    _warmTankMassKg = 0;
    _heaterTemperature = 34;
    _heaterDrainRateKgPerHour = 0;
    _trapFlowRateKgPerHour = 0;
    _condensateSpilledKg = 0;
    _simulatedSeconds = 0;
    _lastClockElapsed = Duration.zero;
    notifyListeners();
  }

  void setReducerFailed(bool value) {
    _reducerFailed = value;
    notifyListeners();
  }

  void setBoilerOutput(double value) => _update(
        () => _boilerOutput = _boundedValue(value, 20, 100, 'boilerOutput'),
      );

  void setRegulatorSetting(double value) => _update(
        () => _regulatorSetting =
            _boundedValue(value, 1, 4.5, 'regulatorSetting'),
      );

  void setInletValve(double value) =>
      _update(() => _inletValve = _boundedValue(value, 0, 100, 'inletValve'));

  void setOutletValve(double value) =>
      _update(() => _outletValve = _boundedValue(value, 0, 100, 'outletValve'));

  void setDrainValve(double value) =>
      _update(() => _drainValve = _boundedValue(value, 0, 100, 'drainValve'));

  double _boundedValue(
      double value, double minimum, double maximum, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'Must be a finite number');
    }
    return value.clamp(minimum, maximum).toDouble();
  }

  void _update(VoidCallback update) {
    update();
    notifyListeners();
  }

  void _step() {
    final now = _clock.elapsed;
    final delta = now - _lastClockElapsed;
    _lastClockElapsed = now;
    final elapsed = delta.inMicroseconds / Duration.microsecondsPerSecond;
    var remaining = elapsed;
    while (remaining > 0) {
      final step = math.min(remaining, _maximumIntegrationStepSeconds);
      _integrate(step);
      remaining -= step;
    }
    _simulatedSeconds += elapsed;
    notifyListeners();
  }

  void _integrate(double seconds) {
    _updateSafetyValveLatch();

    final producedSteamKg = steamProductionKgPerHour / 3600 * seconds;
    final consumedSteamKg = steamFlowKgPerHour / 3600 * seconds;
    final relievedSteamKg = _safetyValveDischargeKgPerHour / 3600 * seconds;
    final minimumSteamMassKg = _steamMassAtGaugePressure(0);
    final maximumSteamMassKg =
        _steamMassAtGaugePressure(maximumBoilerPressureBar);
    _boilerSteamMassKg = (_boilerSteamMassKg +
            producedSteamKg -
            consumedSteamKg -
            relievedSteamKg)
        .clamp(minimumSteamMassKg, maximumSteamMassKg)
        .toDouble();
    _updateSafetyValveLatch();

    final heatInputKw = heaterThermalPowerKw;
    final heatLossKw = _heaterHeatLossKwPerC *
        math.max(_heaterTemperature - ambientTemperatureC, 0);
    _heaterTemperature = (_heaterTemperature +
            (heatInputKw - heatLossKw) / _heaterThermalCapacityKjPerC * seconds)
        .clamp(ambientTemperatureC, 110)
        .toDouble();

    final generatedCondensateKg =
        heatInputKw * seconds * (steamQuality / 100) / _latentHeatKjPerKg;
    final heaterCondensateBeforeDrain =
        _heaterCondensateMassKg + generatedCondensateKg;
    final heaterDrainCapacityKg =
        _heaterOutletCapacityKgPerHour * _outletValve / 100 / 3600 * seconds;
    final heaterDrainKg =
        math.min(heaterCondensateBeforeDrain, heaterDrainCapacityKg);
    _heaterDrainRateKgPerHour = heaterDrainKg / seconds * 3600;
    _heaterCondensateMassKg = _storeCondensate(
      heaterCondensateBeforeDrain - heaterDrainKg,
      _heaterCondensateCapacityKg,
    );

    final condensateBeforeTrap = _condensateMassKg + heaterDrainKg;
    final trapPressureFactor =
        math.sqrt(math.max(workingPressure, 0) / _regulatorSetting);
    final trapCapacityKg = _condensateTrapCapacityKgPerHour *
        _drainValve /
        100 *
        trapPressureFactor /
        3600 *
        seconds;
    final returnedCondensateKg = math.min(condensateBeforeTrap, trapCapacityKg);
    _trapFlowRateKgPerHour = returnedCondensateKg / seconds * 3600;
    _condensateMassKg = _storeCondensate(
      condensateBeforeTrap - returnedCondensateKg,
      condensateBoxCapacityKg,
    );
    _warmTankMassKg = _storeCondensate(
      _warmTankMassKg + returnedCondensateKg,
      warmTankCapacityKg,
    );
  }

  double get _safetyValveDischargeKgPerHour {
    if (!_safetyValveOpen) return 0;
    final pressureAboveSetpoint =
        boilerPressure - _safetyValveOpeningPressureBar;
    return (_safetyValveCapacityKgPerHour *
            pressureAboveSetpoint /
            (maximumBoilerPressureBar - _safetyValveOpeningPressureBar))
        .clamp(0, _safetyValveCapacityKgPerHour)
        .toDouble();
  }

  void _updateSafetyValveLatch() {
    if (_safetyValveOpen) {
      if (boilerPressure <= _safetyValveClosingPressureBar) {
        _safetyValveOpen = false;
      }
    } else if (boilerPressure >= _safetyValveOpeningPressureBar) {
      _safetyValveOpen = true;
    }
  }

  double _storeCondensate(double massKg, double capacityKg) {
    if (massKg > capacityKg) {
      _condensateSpilledKg += massKg - capacityKg;
      return capacityKg;
    }
    return math.max(massKg, 0);
  }

  double _steamMassAtGaugePressure(double pressureBar) {
    final absolutePressureKpa = (pressureBar + _atmosphericPressureBar) * 100;
    return absolutePressureKpa *
        boilerSteamSpaceM3 /
        (_steamGasConstantKjPerKgK * _boilerSteamTemperatureKelvin);
  }

  double _boilerPressureFromMass(double massKg) {
    final absolutePressureBar = massKg *
        _steamGasConstantKjPerKgK *
        _boilerSteamTemperatureKelvin /
        boilerSteamSpaceM3 /
        100;
    return (absolutePressureBar - _atmosphericPressureBar)
        .clamp(0, maximumBoilerPressureBar)
        .toDouble();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock.stop();
    super.dispose();
  }
}
