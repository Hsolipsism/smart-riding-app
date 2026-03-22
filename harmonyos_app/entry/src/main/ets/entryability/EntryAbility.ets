import { AbilityConstant, ConfigurationConstant, UIAbility, Want, common, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ConnectionType } from '../constants/BLEConstants'
import { PreferencesHelper } from '../utils/PreferencesHelper'
import { AutoReconnectManager } from '../common/AutoReconnectManager'

const DOMAIN = 0x0000;

// 初始化全局连接状态
AppStorage.setOrCreate('connectionType', ConnectionType.None)
AppStorage.setOrCreate('connectedDeviceName', '')
AppStorage.setOrCreate('nearLinkDeviceName', '')

// 需要申请的权限列表
const PERMISSIONS: Array<Permissions> = [
  'ohos.permission.ACCESS_NEARLINK'
];

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // 初始化持久化存储
    this.initPreferences();

    // 请求星闪权限
    this.requestNearLinkPermission();
  }

  private async initPreferences(): Promise<void> {
    const preferencesHelper = PreferencesHelper.getInstance();
    await preferencesHelper.init(this.context);

    // 加载保存的星闪设备名称
    const savedDeviceName = await preferencesHelper.getString('nearLinkDeviceName', '');
    if (savedDeviceName) {
      AppStorage.set('nearLinkDeviceName', savedDeviceName);
    }

    // 初始化自动重连管理器
    const autoReconnectManager = AutoReconnectManager.getInstance();
    await autoReconnectManager.init();
  }

  /**
   * 请求星闪连接权限
   */
  private requestNearLinkPermission(): void {
    hilog.info(DOMAIN, 'testTag', 'Requesting NearLink permission');
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let context: common.UIAbilityContext = this.context as common.UIAbilityContext;

    atManager.requestPermissionsFromUser(context, PERMISSIONS)
      .then(() => {
        hilog.info(DOMAIN, 'testTag', 'Request permission success');
      })
      .catch((err: BusinessError) => {
        hilog.error(DOMAIN, 'testTag', 'Request permission failed, err: %{public}s', JSON.stringify(err));
      });
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
