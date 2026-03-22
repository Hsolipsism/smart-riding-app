import { AutoReconnectManager } from '../common/AutoReconnectManager'
import { promptAction } from '@kit.ArkUI'

@CustomDialog
export struct StarLinkStrategyDialog {
  controller: CustomDialogController
  autoReconnectManager: AutoReconnectManager = AutoReconnectManager.getInstance()

  @State isEnabled: boolean = false
  @State intervalValue: number = 5

  build() {
    Column() {
      Text('星闪连接策略')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 20 })

      // 开关行
      Row() {
        Text('自动重连')
          .fontSize(16)
          .fontColor('#333333')

        Blank()

        Toggle({ type: ToggleType.Switch, isOn: this.isEnabled })
          .selectedColor('#007AFF')
          .onChange((isOn: boolean) => {
            this.isEnabled = isOn
          })
      }
      .width('100%')
      .padding({ bottom: 16 })

      // 间隔行
      Row() {
        Text('重连间隔')
          .fontSize(16)
          .fontColor('#333333')

        Blank()

        Text(this.intervalValue.toString() + ' 秒')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ right: 8 })
      }
      .width('100%')
      .padding({ bottom: 8 })

      // 滑块
      Slider({
        value: this.intervalValue,
        min: 1,
        max: 30,
        step: 1,
        style: SliderStyle.OutSet
      })
        .width('100%')
        .showTips(false)
        .onChange((value: number) => {
          this.intervalValue = Math.round(value)
        })

      // 保存按钮
      Button('保存')
        .width('100%')
        .height(40)
        .backgroundColor('#007AFF')
        .fontColor('#FFFFFF')
        .borderRadius(20)
        .margin({ top: 20 })
        .onClick(async () => {
          await this.autoReconnectManager.setEnabled(this.isEnabled)
          await this.autoReconnectManager.setInterval(this.intervalValue)
          this.controller.close()
          promptAction.showToast({ message: '设置已保存', duration: 2000 })
        })
    }
    .width('85%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  aboutToAppear(): void {
    this.isEnabled = this.autoReconnectManager.isReconnectEnabled()
    this.intervalValue = this.autoReconnectManager.getInterval()
  }
}
