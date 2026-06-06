import 'package:flutter/material.dart';

void main() => runApp(const ForcedUninstallerApp());
class ForcedUninstallerApp extends StatelessWidget {
  const ForcedUninstallerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: '强制卸载工具', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true, brightness: Brightness.dark),
    home: const UninstallerHomePage());
}

class InstalledApp {
  String name, version, size, publisher, installDate;
  bool selected;
  InstalledApp({required this.name, required this.version, required this.size, required this.publisher, required this.installDate, this.selected = false});
}

class UninstallerHomePage extends StatefulWidget {
  const UninstallerHomePage({super.key});
  @override
  State<UninstallerHomePage> setState() => _UninstallerHomePageState();
}

class _UninstallerHomePageState extends State<UninstallerHomePage> {
  List<InstalledApp> _apps = [
    InstalledApp(name: 'Google Chrome', version: '120.0.6099', size: '450 MB', publisher: 'Google LLC', installDate: '2024-01-10'),
    InstalledApp(name: 'Visual Studio Code', version: '1.85.1', size: '320 MB', publisher: 'Microsoft', installDate: '2024-01-05'),
    InstalledApp(name: 'Adobe Reader', version: '23.008', size: '280 MB', publisher: 'Adobe Inc.', installDate: '2023-12-20'),
    InstalledApp(name: 'WinRAR', version: '7.00', size: '45 MB', publisher: 'RARLAB', installDate: '2023-11-15'),
    InstalledApp(name: '腾讯QQ', version: '9.9.5', size: '680 MB', publisher: '腾讯', installDate: '2024-01-08'),
    InstalledApp(name: '2345浏览器', version: '12.4', size: '520 MB', publisher: '2345', installDate: '2023-10-01'),
    InstalledApp(name: '鲁大师', version: '7.1', size: '380 MB', publisher: '鲁大师', installDate: '2023-09-15'),
  ];

  String _searchQuery = '';
  String _sortBy = 'name';
  bool _uninstalling = false;

  List<InstalledApp> get _filtered {
    var list = _searchQuery.isEmpty ? _apps : _apps.where((a) => a.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    list.sort((a, b) => _sortBy == 'name' ? a.name.compareTo(b.name) : _sortBy == 'size' ? b.size.compareTo(a.size) : b.installDate.compareTo(a.installDate));
    return list;
  }

  void _uninstallSelected() {
    final selected = _apps.where((a) => a.selected).toList();
    if (selected.isEmpty) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('确认卸载'), content: Text('确定卸载以下 ${selected.length} 个应用？\n\n${selected.map((a) => '• ${a.name}').join('\n')}'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), FilledButton(onPressed: () {
        Navigator.pop(ctx);
        setState(() { _uninstalling = true; });
        Future.delayed(const Duration(seconds: 2), () {
          setState(() { _apps.removeWhere((a) => a.selected); _uninstalling = false; });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已卸载 ${selected.length} 个应用'), behavior: SnackBarBehavior.floating));
        });
      }, child: const Text('卸载'))],
    ));
  }

  void _forceRemove(InstalledApp app) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('强制移除'), content: Text('强制移除「${app.name}」的所有文件和注册表项？\n\n⚠️ 此操作不可恢复！'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), FilledButton(onPressed: () { setState(() => _apps.removeWhere((a) => a.name == app.name)); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已强制移除: ${app.name}'), behavior: SnackBarBehavior.floating)); }, style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('强制移除'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🗑️ 强制卸载'), centerTitle: true, actions: [
        PopupMenuButton<String>(icon: const Icon(Icons.sort), itemBuilder: (ctx) => [const PopupMenuItem(value: 'name', child: Text('按名称')), const PopupMenuItem(value: 'size', child: Text('按大小')), const PopupMenuItem(value: 'date', child: Text('按日期'))], onSelected: (v) => setState(() => _sortBy = v)),
      ]),
      body: Column(children: [
        // 搜索和统计
        Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          TextField(onChanged: (v) => setState(() => _searchQuery = v), decoration: InputDecoration(hintText: '搜索应用...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)), prefixIcon: const Icon(Icons.search), isDense: true)),
          const SizedBox(height: 8),
          Row(children: [Text('共 ${_filtered.length} 个应用', style: const TextStyle(color: Colors.grey, fontSize: 13)), const Spacer(), Text('${_filtered.where((a) => a.selected).length} 个选中', style: const TextStyle(color: Colors.red, fontSize: 13))]),
        ])),
        const Divider(height: 1),
        // 应用列表
        Expanded(child: _filtered.isEmpty ? const Center(child: Text('没有找到应用')) : ListView.builder(itemCount: _filtered.length, itemBuilder: (ctx, i) {
          final app = _filtered[i];
          return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: ExpansionTile(
            leading: Checkbox(value: app.selected, onChanged: (v) => setState(() => app.selected = v!)),
            title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${app.version} • ${app.size}', style: const TextStyle(fontSize: 12)),
            trailing: IconButton(icon: const Icon(Icons.delete_forever, color: Colors.red), onPressed: () => _forceRemove(app), tooltip: '强制移除'),
            children: [Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _infoRow('版本', app.version), _infoRow('大小', app.size), _infoRow('发布者', app.publisher), _infoRow('安装日期', app.installDate),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.folder_open), label: const Text('打开目录'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.info_outline), label: const Text('详细信息'))),
              ]),
            ]))],
          );
        })),
        // 操作按钮
        Container(padding: const EdgeInsets.all(12), child: Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _apps.where((a) => a.selected).isEmpty ? null : () => setState(() { for (var a in _apps) { a.selected = false; } }), icon: const Icon(Icons.deselect), label: const Text('取消全选'))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton.icon(onPressed: _apps.where((a) => a.selected).isEmpty || _uninstalling ? null : _uninstallSelected, icon: _uninstalling ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.delete), label: Text(_uninstalling ? '卸载中...' : '卸载选中'), style: FilledButton.styleFrom(backgroundColor: Colors.red))),
        ])),
      ]),
    );
  }

  Widget _infoRow(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))), Text(value, style: const TextStyle(fontSize: 13))]));
}
