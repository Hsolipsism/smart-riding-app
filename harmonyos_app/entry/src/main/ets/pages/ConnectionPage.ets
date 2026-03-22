import { BLEManager, BLEDevice } from '../common/BLEManager'
import { NearLinkManager, NearLinkDevice } from '../common/NearLinkManager'
import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { ConnectionType } from '../constants/BLEConstants'
import { PreferencesHelper } from '../utils/PreferencesHelper'

// 星闪设备ID输入弹窗
@CustomDialog
export struct StarflashDeviceIdDialog {
  controller: CustomDialogController
  savedDeviceName: string = ''
  onDeviceIdConfirm!: (deviceName: string) => void

  @State deviceName: string = ''

  build() {
    Column() {
      Text('星闪设备ID')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 16 })

      Text('请输入星闪设备名称')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 8 })

      TextInput({ placeholder: '设备名称', text: this.savedDeviceName })
        .width('100%')
        .height(44)
        .fontSize(16)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')
        .margin({ bottom: 20 })
        .onChange((value: string) => {
          this.deviceName = value
        })

      Row() {
        Button('取消')
          .width('45%')
          .height(40)
          .backgroundColor('#E5E5E5')
          .fontColor('#333333')
          .borderRadius(20)
          .onClick(() => {
            this.controller.close()
          })

        Button('保存')
          .width('45%')
          .height(40)
          .backgroundColor('#007AFF')
          .fontColor('#FFFFFF')
          .borderRadius(20)
          .onClick(() => {
            this.controller.close()
            if (this.deviceName.length > 0) {
              this.onDeviceIdConfirm(this.deviceName)
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('85%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }
}

// BLE扫描弹窗
@CustomDialog
export struct BLEScanDialog {
  controller: CustomDialogController
  bleManager!: BLEManager
  onDeviceSelected!: (device: BLEDevice) => void

  @State devices: BLEDevice[] = []
  @State isScanning: boolean = false

  build() {
    Column() {
      Text('选择蓝牙设备')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 16 })

      if (this.devices.length === 0 && !this.isScanning) {
        Text('正在扫描...')
          .fontSize(14)
          .fontColor('#666666')
          .height(200)
          .width('100%')
          .textAlign(TextAlign.Center)
      } else {
        List() {
          ForEach(this.devices, (device: BLEDevice) => {
            ListItem() {
              Row() {
                Column() {
                  Text(device.deviceName || '未知设备')
                    .fontSize(16)
                    .fontColor('#333333')
                  Text(device.deviceId)
                    .fontSize(12)
                    .fontColor('#999999')
                }
                .alignItems(HorizontalAlign.Start)

                Blank()

                Text(device.rssi.toString() + ' dBm')
                  .fontSize(12)
                  .fontColor('#999999')
              }
              .width('100%')
              .padding(10)
              .onClick(() => {
                this.onDeviceSelected(device)
              })
            }
            .padding(5)
          })
        }
        .height(200)
        .width('100%')
      }

      Text(this.isScanning ? '停止扫描' : '重新扫描')
        .fontSize(16)
        .fontColor('#007AFF')
        .margin({ top: 16 })
        .onClick(() => {
          if (this.isScanning) {
            this.bleManager.stopScan()
            this.isScanning = false
          } else {
            this.startScan()
          }
        })
    }
    .width('90%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
  }

  aboutToAppear(): void {
    this.startScan()
  }

  aboutToDisappear(): void {
    this.bleManager.stopScan()
  }

  private startScan(): void {
    this.isScanning = true
    this.bleManager.startScan((devices: BLEDevice[]) => {
      this.devices = devices
    })
  }
}

// 星闪设备名称输入弹窗
@CustomDialog
export struct StarflashInputDialog {
  controller: CustomDialogController
  onDeviceNameConfirm!: (deviceName: string) => void

  @State deviceName: string = ''

  build() {
    Column() {
      Text('星闪连接')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 16 })

      Text('请输入设备名称')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 8 })

      TextInput({ placeholder: '设备名称' })
        .width('100%')
        .height(44)
        .fontSize(16)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')
        .margin({ bottom: 20 })
        .onChange((value: string) => {
          this.deviceName = value
        })

      Row() {
        Button('取消')
          .width('45%')
          .height(40)
          .backgroundColor('#E5E5E5')
          .fontColor('#333333')
          .borderRadius(20)
          .onClick(() => {
            this.controller.close()
          })

        Button('连接')
          .width('45%')
          .height(40)
          .backgroundColor('#007AFF')
          .fontColor('#FFFFFF')
          .borderRadius(20)
          .onClick(() => {
            this.controller.close()
            if (this.deviceName.length > 0) {
              this.onDeviceNameConfirm(this.deviceName)
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('85%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }
}

@Component
export struct ConnectionPage {
  private bleManager: BLEManager = BLEManager.getInstance()
  private nearLinkManager: NearLinkManager = NearLinkManager.getInstance()
  private bleScanDialogController: CustomDialogController | null = null
  private starflashDialogController: CustomDialogController | null = null
  private starflashDeviceIdDialogController: CustomDialogController | null = null

  @StorageLink('connectionType') connectionType: ConnectionType = ConnectionType.None
  @StorageLink('connectedDeviceName') connectedDeviceName: string = ''
  @StorageLink('nearLinkDeviceName') nearLinkDeviceName: string = ''

  aboutToAppear(): void {
    // 设置 BLE 连接状态回调
    this.bleManager.setConnectionCallback((connected: boolean, deviceId: string) => {
      if (connected) {
        AppStorage.set('connectionType', ConnectionType.BLE)
        AppStorage.set('connectedDeviceName', deviceId)
      } else {
        if (this.connectionType === ConnectionType.BLE) {
          AppStorage.set('connectionType', ConnectionType.None)
          AppStorage.set('connectedDeviceName', '')
        }
      }
    })

    // 设置星闪连接状态回调
    this.nearLinkManager.setConnectionCallback((success: boolean, message: string) => {
      if (success) {
        AppStorage.set('connectionType', ConnectionType.NearLink)
        AppStorage.set('connectedDeviceName', '星闪设备')
      } else {
        if (this.connectionType === ConnectionType.NearLink) {
          AppStorage.set('connectionType', ConnectionType.None)
          AppStorage.set('connectedDeviceName', '')
        }
      }
      promptAction.showToast({ message: message, duration: 2000 })
    })
  }

  build() {
    Column() {
      // 当前连接状态
      Row() {
        if (this.connectionType === ConnectionType.None) {
          Image($r('app.media.ic_public_link'))
            .width(24)
            .height(24)
          Text('未连接')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ left: 12 })
        } else if (this.connectionType === ConnectionType.BLE) {
          Image($r('app.media.ic_public_bluetooth'))
            .width(24)
            .height(24)
          Text('蓝牙已连接')
            .fontSize(16)
            .fontColor('#007AFF')
            .margin({ left: 12 })
        } else if (this.connectionType === ConnectionType.NearLink) {
          Image($r('app.media.ic_public_starflash'))
            .width(24)
            .height(24)
          Text('星闪已连接')
            .fontSize(16)
            .fontColor('#FF9500')
            .margin({ left: 12 })
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      Divider()

      // 蓝牙连接按钮
      Row() {
        Image($r('app.media.ic_public_bluetooth'))
          .width(20)
          .height(20)
        Text('蓝牙连接')
          .fontSize(16)
          .fontColor('#333333')
          .margin({ left: 12 })
        Blank()
        Text('>')
          .fontSize(18)
          .fontColor('#999999')
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .onClick(() => {
        if (this.connectionType !== ConnectionType.None) {
          return
        }
        this.openBLEScanDialog()
      })

      Divider()

      // 星闪连接按钮
      Row() {
        Image($r('app.media.ic_public_starflash'))
          .width(20)
          .height(20)
        Text('星闪连接')
          .fontSize(16)
          .fontColor('#333333')
          .margin({ left: 12 })
        Blank()
        Text('>')
          .fontSize(18)
          .fontColor('#999999')
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .onClick(() => {
        if (this.connectionType !== ConnectionType.None) {
          return
        }
        // 如果有保存的设备名，直接连接
        if (this.nearLinkDeviceName.length > 0) {
          this.startStarflashScan(this.nearLinkDeviceName)
        } else {
          // 没有保存的，打开输入对话框
          this.openStarflashInputDialog()
        }
      })

      Divider()

      // 星闪设备ID按钮
      Row() {
        Image($r('app.media.ic_public_settings'))
          .width(20)
          .height(20)
        Text('星闪设备ID')
          .fontSize(16)
          .fontColor('#333333')
          .margin({ left: 12 })
        Blank()
        if (this.nearLinkDeviceName.length > 0) {
          Text(this.nearLinkDeviceName)
            .fontSize(12)
            .fontColor('#666666')
            .margin({ right: 8 })
        }
        Text('>')
          .fontSize(18)
          .fontColor('#999999')
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .onClick(() => {
        this.openStarflashDeviceIdDialog()
      })

      Divider()

      // 断开连接按钮
      Row() {
        Image($r('app.media.ic_public_cancel'))
          .width(20)
          .height(20)
        Text('断开连接')
          .fontSize(16)
          .fontColor('#FF3B30')
          .margin({ left: 12 })
        Blank()
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .onClick(() => {
        if (this.connectionType === ConnectionType.None) {
          return
        }
        this.disconnectCurrent()
      })
      .opacity(this.connectionType === ConnectionType.None ? 0.5 : 1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  private openBLEScanDialog(): void {
    const context = getContext(this) as common.UIAbilityContext
    this.bleManager.setContext(context)

    this.bleManager.requestPermissions().then((granted: boolean) => {
      if (!granted) {
        promptAction.showToast({ message: '权限申请失败', duration: 2000 })
        return
      }

      this.bleScanDialogController = new CustomDialogController({
        builder: BLEScanDialog({
          bleManager: this.bleManager,
          onDeviceSelected: (device: BLEDevice) => {
            this.connectBLE(device)
          }
        }),
        alignment: DialogAlignment.Center,
        backgroundColor: 0xFFFFFFFF
      })

      this.bleScanDialogController.open()
    })
  }

  private openStarflashInputDialog(): void {
    this.starflashDialogController = new CustomDialogController({
      builder: StarflashInputDialog({
        onDeviceNameConfirm: (deviceName: string) => {
          this.startStarflashScan(deviceName)
        }
      }),
      alignment: DialogAlignment.Center,
      backgroundColor: 0xFFFFFFFF
    })
    this.starflashDialogController.open()
  }

  private openStarflashDeviceIdDialog(): void {
    this.starflashDeviceIdDialogController = new CustomDialogController({
      builder: StarflashDeviceIdDialog({
        savedDeviceName: this.nearLinkDeviceName,
        onDeviceIdConfirm: async (deviceName: string) => {
          AppStorage.set('nearLinkDeviceName', deviceName)
          await PreferencesHelper.getInstance().putString('nearLinkDeviceName', deviceName)
          promptAction.showToast({ message: '已保存', duration: 2000 })
        }
      }),
      alignment: DialogAlignment.Center,
      backgroundColor: 0xFFFFFFFF
    })
    this.starflashDeviceIdDialogController.open()
  }

  private async connectBLE(device: BLEDevice): Promise<void> {
    if (this.bleScanDialogController) {
      this.bleScanDialogController.close()
      this.bleScanDialogController = null
    }

    if (this.connectionType === ConnectionType.NearLink) {
      this.nearLinkManager.disconnect()
    }

    promptAction.showToast({ message: '连接中...', duration: 2000 })

    const success: boolean = await this.bleManager.connect(device.deviceId)

    if (success) {
      AppStorage.set('connectionType', ConnectionType.BLE)
      AppStorage.set('connectedDeviceName', device.deviceName || device.deviceId)
    }
  }

  private startStarflashScan(deviceName: string): void {
    if (this.connectionType === ConnectionType.BLE) {
      this.bleManager.disconnect()
      this.bleManager.close()
    }

    promptAction.showToast({ message: `正在扫描: ${deviceName}`, duration: 2000 })

    this.nearLinkManager.startScan(deviceName, (devices: NearLinkDevice[]) => {
      console.info('NearLink scan devices:', devices.length)
    })
  }

  private disconnectCurrent(): void {
    if (this.connectionType === ConnectionType.BLE) {
      this.bleManager.disconnect()
      this.bleManager.close()
      AppStorage.set('connectionType', ConnectionType.None)
      AppStorage.set('connectedDeviceName', '')
    } else if (this.connectionType === ConnectionType.NearLink) {
      this.nearLinkManager.disconnect()
      AppStorage.set('connectionType', ConnectionType.None)
      AppStorage.set('connectedDeviceName', '')
    }
    promptAction.showToast({ message: '已断开', duration: 2000 })
  }
}
