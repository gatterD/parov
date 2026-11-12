import 'package:flutter/material.dart';

import '../models/steam_simulation.dart';
import '../theme/app_theme.dart';
import 'status_tag.dart';

class SystemOverview extends StatelessWidget {
  const SystemOverview({super.key, required this.simulation});

  final SteamSimulation simulation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Схема системы',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          const Text('Поток пара и возврат конденсата',
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: .06)),
              ),
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth > 680
                    ? _HorizontalDiagram(simulation: simulation)
                    : _VerticalDiagram(simulation: simulation),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _Legend(color: AppColors.steam, label: 'Пар'),
              _Legend(color: AppColors.water, label: 'Конденсат'),
              _Legend(color: AppColors.danger, label: 'Сброс давления'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  title: 'КОТЁЛ',
                  value: simulation.boilerPressure.toStringAsFixed(1),
                  unit: 'бар',
                  color: simulation.safetyValveOpen
                      ? AppColors.danger
                      : AppColors.steam,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  title: 'МАГИСТРАЛЬ',
                  value: simulation.workingPressure.toStringAsFixed(1),
                  unit: 'бар',
                  color: AppColors.steam,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  title: 'ГРЕЛКИ',
                  value: simulation.heaterTemperature.toStringAsFixed(0),
                  unit: '°C',
                  color: AppColors.water,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HorizontalDiagram extends StatelessWidget {
  const _HorizontalDiagram({required this.simulation});

  final SteamSimulation simulation;

  @override
  Widget build(BuildContext context) {
    const diagramWidth = 1050.0;
    final steamIntensity = simulation.steamFlowKgPerHour /
        SteamSimulation.distributionCapacityKgPerHour;
    final condensateIntensity = simulation.returnFlowKgPerHour / 220;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: diagramWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BranchLabel(
              label:
                  'ПАР · ${simulation.steamFlowKgPerHour.toStringAsFixed(0)} кг/ч',
              color: AppColors.steam,
            ),
            Row(
              children: [
                _ProcessNode(
                  icon: Icons.local_fire_department,
                  title: 'Котёл',
                  subtitle:
                      '${simulation.boilerPressure.toStringAsFixed(1)} бар',
                  color: simulation.boilerOverpressure
                      ? AppColors.danger
                      : AppColors.steam,
                  active: steamIntensity > 0,
                ),
                _FlowArrow(flow: steamIntensity, color: AppColors.steam),
                _ProcessNode(
                  icon: Icons.tune,
                  title: 'Редукционный клапан',
                  subtitle: simulation.reducerFailed
                      ? 'Авария · открыт'
                      : '${simulation.boilerPressure.toStringAsFixed(1)} → '
                          '${simulation.workingPressure.toStringAsFixed(1)} бар',
                  color: simulation.reducerFailed
                      ? AppColors.danger
                      : AppColors.steam,
                  active: steamIntensity > 0,
                ),
                _FlowArrow(flow: steamIntensity, color: AppColors.steam),
                _ProcessNode(
                  icon: Icons.water_drop_outlined,
                  title: 'Сепаратор',
                  subtitle:
                      'Сухость ${simulation.steamQuality.toStringAsFixed(0)}%',
                  color: AppColors.water,
                  active: steamIntensity > 0,
                ),
                _FlowArrow(flow: steamIntensity, color: AppColors.steam),
                _ProcessNode(
                  icon: Icons.hub_outlined,
                  title: 'Распределительная коробка',
                  subtitle:
                      '${simulation.steamFlowKgPerHour.toStringAsFixed(0)} кг/ч',
                  color: AppColors.steam,
                  active: steamIntensity > 0,
                ),
                _FlowArrow(flow: steamIntensity, color: AppColors.steam),
                _ProcessNode(
                  icon: Icons.settings,
                  title: 'Клапан 8',
                  subtitle:
                      'Подача · ${simulation.inletValve.toStringAsFixed(0)}%',
                  color: AppColors.steam,
                  active: steamIntensity > 0,
                ),
                _FlowArrow(flow: steamIntensity, color: AppColors.steam),
                _ProcessNode(
                  icon: Icons.radar,
                  title: 'Грелки',
                  subtitle:
                      '${simulation.heaterTemperature.toStringAsFixed(0)} °C',
                  color: AppColors.water,
                  active: steamIntensity > 0,
                ),
              ],
            ),
            _BranchLabel(
              label: 'ВЕТВЬ ПРЕДОХРАНИТЕЛЬНОГО СБРОСА',
              color: simulation.safetyValveOpen
                  ? AppColors.danger
                  : AppColors.muted,
            ),
            Row(
              children: [
                _ProcessNode(
                  icon: Icons.local_fire_department,
                  title: 'Отбор от котла',
                  subtitle: 'Открытие при 6.0 бар',
                  color: AppColors.muted,
                  active: simulation.safetyValveOpen,
                ),
                _FlowArrow(
                  flow: simulation.safetyValveDischargeKgPerHour / 700,
                  color: AppColors.danger,
                ),
                _ProcessNode(
                  icon: Icons.emergency,
                  title: 'Предохранительный клапан',
                  subtitle: simulation.safetyValveOpen
                      ? 'Открыт · сброс пара'
                      : 'Закрыт · сброс при 6.0 бар',
                  color: simulation.safetyValveOpen
                      ? AppColors.danger
                      : AppColors.muted,
                  active: simulation.safetyValveOpen,
                ),
                _FlowArrow(
                  flow: simulation.safetyValveDischargeKgPerHour / 700,
                  color: AppColors.danger,
                ),
                _ProcessNode(
                  icon: Icons.north_east,
                  title: 'Сброс пара',
                  subtitle: simulation.safetyValveOpen
                      ? '${simulation.safetyValveDischargeKgPerHour.toStringAsFixed(0)} кг/ч'
                      : 'Закрытие при 5.7 бар',
                  color: simulation.safetyValveOpen
                      ? AppColors.danger
                      : AppColors.muted,
                  active: simulation.safetyValveOpen,
                ),
              ],
            ),
            _BranchLabel(
              label: 'ВОЗВРАТ КОНДЕНСАТА · '
                  '${simulation.returnFlowKgPerHour.toStringAsFixed(0)} кг/ч',
              color: AppColors.water,
            ),
            Row(
              children: [
                _ProcessNode(
                  icon: Icons.radar,
                  title: 'Выход грелок',
                  subtitle: 'Конденсат '
                      '${(simulation.heaterCondensateLevel * 100).toStringAsFixed(0)}%',
                  color: AppColors.water,
                  active: condensateIntensity > 0,
                ),
                _FlowArrow(flow: condensateIntensity, color: AppColors.water),
                _ProcessNode(
                  icon: Icons.settings,
                  title: 'Клапан 10',
                  subtitle:
                      'Отвод · ${simulation.outletValve.toStringAsFixed(0)}%',
                  color: AppColors.water,
                  active: condensateIntensity > 0,
                ),
                _FlowArrow(flow: condensateIntensity, color: AppColors.water),
                _ProcessNode(
                  icon: Icons.inbox_outlined,
                  title: 'Конденсатная коробка',
                  subtitle:
                      'Уровень ${(simulation.condensateLevel * 100).toStringAsFixed(0)}%',
                  color: AppColors.water,
                  active: condensateIntensity > 0,
                ),
                _FlowArrow(flow: condensateIntensity, color: AppColors.water),
                _ProcessNode(
                  icon: Icons.settings,
                  title: 'Клапан 13',
                  subtitle:
                      'Возврат · ${simulation.drainValve.toStringAsFixed(0)}%',
                  color: AppColors.water,
                  active: condensateIntensity > 0,
                ),
                _FlowArrow(flow: condensateIntensity, color: AppColors.water),
                _ProcessNode(
                  icon: Icons.water,
                  title: 'Конденсатоотводчик',
                  subtitle:
                      '${simulation.returnFlowKgPerHour.toStringAsFixed(0)} кг/ч',
                  color: AppColors.water,
                  active: condensateIntensity > 0,
                ),
                _FlowArrow(flow: condensateIntensity, color: AppColors.water),
                _ProcessNode(
                  icon: Icons.inventory_2_outlined,
                  title: 'Тёплый ящик',
                  subtitle:
                      'Уровень ${(simulation.warmTankLevel * 100).toStringAsFixed(0)}%',
                  color: AppColors.water,
                  active: condensateIntensity > 0,
                ),
              ],
            ),
            if (simulation.safetyValveOpen)
              const StatusTag(label: 'СБРОС ПАРА', color: AppColors.danger),
          ],
        ),
      ),
    );
  }
}

class _VerticalDiagram extends StatelessWidget {
  const _VerticalDiagram({required this.simulation});

  final SteamSimulation simulation;

  @override
  Widget build(BuildContext context) {
    final steamIntensity = simulation.steamFlowKgPerHour /
        SteamSimulation.distributionCapacityKgPerHour;
    final condensateIntensity = simulation.returnFlowKgPerHour / 220;

    return SingleChildScrollView(
      child: Column(
        children: [
          _VerticalStage(
            number: '01',
            title: 'Паровой котёл',
            subtitle: '${simulation.boilerPressure.toStringAsFixed(1)} бар',
            icon: Icons.local_fire_department,
            color: simulation.boilerOverpressure
                ? AppColors.danger
                : AppColors.steam,
            active: steamIntensity > 0,
          ),
          const _BranchLabel(
            label: 'ОТ КОТЛА: ПАРОВАЯ МАГИСТРАЛЬ И ВЕТВЬ СБРОСА',
            color: AppColors.muted,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _FlowArrow(
                      flow: steamIntensity,
                      color: AppColors.steam,
                      vertical: true,
                    ),
                    _VerticalStage(
                      number: '02',
                      title: 'Редуктор',
                      subtitle: simulation.reducerFailed
                          ? 'Отказ · выход '
                              '${simulation.boilerPressure.toStringAsFixed(1)} бар'
                          : '${simulation.boilerPressure.toStringAsFixed(1)} → '
                              '${simulation.workingPressure.toStringAsFixed(1)} бар',
                      icon: Icons.tune,
                      color: simulation.reducerFailed
                          ? AppColors.danger
                          : AppColors.steam,
                      active: steamIntensity > 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    _ProcessNode(
                      icon: Icons.emergency,
                      title: 'Предохранительный клапан',
                      subtitle: simulation.safetyValveOpen
                          ? 'Открыт · '
                              '${simulation.safetyValveDischargeKgPerHour.toStringAsFixed(0)} кг/ч'
                          : 'Открытие 6.0 · закрытие 5.7 бар',
                      color: simulation.safetyValveOpen
                          ? AppColors.danger
                          : AppColors.muted,
                      active: simulation.safetyValveOpen,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _FlowArrow(
                          flow: simulation.safetyValveDischargeKgPerHour / 700,
                          color: AppColors.danger,
                        ),
                        const Flexible(
                          child: Text(
                            'Сброс пара',
                            style: TextStyle(
                                color: AppColors.danger, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          _FlowArrow(
            flow: steamIntensity,
            color: AppColors.steam,
            vertical: true,
          ),
          _VerticalStage(
            number: '03',
            title: 'Сепаратор и распределительная коробка',
            subtitle:
                'Сухость ${simulation.steamQuality.toStringAsFixed(0)}% · '
                '${simulation.steamFlowKgPerHour.toStringAsFixed(0)} кг/ч',
            icon: Icons.water_drop_outlined,
            color: AppColors.water,
            active: steamIntensity > 0,
          ),
          _FlowArrow(
            flow: steamIntensity,
            color: AppColors.steam,
            vertical: true,
          ),
          _VerticalStage(
            number: '03',
            title: 'Отопительная магистраль · клапан 8',
            subtitle: 'Подача ${simulation.inletValve.toStringAsFixed(0)}% · '
                '${simulation.steamFlowKgPerHour.toStringAsFixed(0)} кг/ч',
            icon: Icons.settings,
            color: AppColors.steam,
            active: steamIntensity > 0,
          ),
          _FlowArrow(
            flow: steamIntensity,
            color: AppColors.steam,
            vertical: true,
          ),
          _VerticalStage(
            number: '04',
            title: 'Грелки',
            subtitle: '${simulation.heaterTemperature.toStringAsFixed(0)} °C',
            icon: Icons.device_thermostat,
            color: AppColors.water,
            active: steamIntensity > 0,
          ),
          _FlowArrow(
            flow: condensateIntensity,
            color: AppColors.water,
            vertical: true,
          ),
          _VerticalStage(
            number: '05',
            title: 'Клапан 10 · выход из грелок',
            subtitle: 'Открытие ${simulation.outletValve.toStringAsFixed(0)}%',
            icon: Icons.settings,
            color: AppColors.water,
            active: condensateIntensity > 0,
          ),
          _FlowArrow(
            flow: condensateIntensity,
            color: AppColors.water,
            vertical: true,
          ),
          _VerticalStage(
            number: '06',
            title: 'Конденсатная коробка',
            subtitle:
                'Уровень ${(simulation.condensateLevel * 100).toStringAsFixed(0)}%',
            icon: Icons.inbox_outlined,
            color: AppColors.water,
            active: condensateIntensity > 0,
          ),
          _FlowArrow(
            flow: condensateIntensity,
            color: AppColors.water,
            vertical: true,
          ),
          _VerticalStage(
            number: '07',
            title: 'Клапан 13 · конденсатоотводчик',
            subtitle: 'Клапан ${simulation.drainValve.toStringAsFixed(0)}% · '
                '${simulation.returnFlowKgPerHour.toStringAsFixed(0)} кг/ч',
            icon: Icons.settings,
            color: AppColors.water,
            active: condensateIntensity > 0,
          ),
          _FlowArrow(
            flow: condensateIntensity,
            color: AppColors.water,
            vertical: true,
          ),
          _VerticalStage(
            number: '08',
            title: 'Тёплый ящик',
            subtitle:
                'Уровень ${(simulation.warmTankLevel * 100).toStringAsFixed(0)}%',
            icon: Icons.inventory_2_outlined,
            color: AppColors.water,
            active: condensateIntensity > 0,
          ),
        ],
      ),
    );
  }
}

class _ProcessNode extends StatelessWidget {
  const _ProcessNode({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.active,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? color.withValues(alpha: .48) : Colors.white10,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow({
    required this.flow,
    required this.color,
    this.vertical = false,
  });

  final double flow;
  final Color color;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final intensity = flow.clamp(0, 1).toDouble();
    final visibleColor = color.withValues(alpha: .18 + .82 * intensity);
    final thickness = 1.5 + 3 * intensity;

    return SizedBox(
      width: vertical ? 32 : 25,
      height: vertical ? 26 : null,
      child: vertical
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: thickness,
                  height: 7,
                  color: visibleColor,
                ),
                Icon(Icons.keyboard_arrow_down, color: visibleColor, size: 18),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: thickness,
                  color: visibleColor,
                ),
                Icon(Icons.chevron_right, color: visibleColor, size: 18),
              ],
            ),
    );
  }
}

class _BranchLabel extends StatelessWidget {
  const _BranchLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: .6,
          ),
        ),
      ),
    );
  }
}

class _VerticalStage extends StatelessWidget {
  const _VerticalStage({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.active,
  });

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: active ? color.withValues(alpha: .36) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Text(number,
              style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          const SizedBox(width: 12),
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String title;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Text(unit,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11)),
      ],
    );
  }
}
