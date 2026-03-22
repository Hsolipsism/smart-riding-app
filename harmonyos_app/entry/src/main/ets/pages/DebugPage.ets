import { AutoReconnectManager } from '../common/AutoReconnectManager'
import { StarLinkStrategyDialog } from './StarLinkStrategyDialog'

@Component
export struct DebugPage {
  private autoReconnectManager: AutoReconnectManager = AutoReconnectManager.getInstance()
  private strategyDialogController: CustomDialogController | null = null

  @StorageLink('connectionType') connectionType: number = 0

  build() {
    Column() {
      // 星闪连接策略卡片
      Column() {
        Row() {
          Image($r('app.media.ic_public_starflash'))
            .width(24)
            .height(24)

          Text('星闪连接策略')
            .fontSize(16)
            .fontColor('#333333')
            .margin({ left: 12 })

          Blank()

          Text(this.autoReconnectManager.isReconnectEnabled() ? '已开启' : '已关闭')
            .fontSize(12)
            .fontColor(this.autoReconnectManager.isReconnectEnabled() ? '#007AFF' : '#999999')
            .margin({ right: 8 })

          Text('>')
            .fontSize(18)
            .fontColor('#999999')
        }
        .width('100%')
        .padding(16)
        .onClick(() => {
          this.openStrategyDialog()
        })
      }
      .width('100%')
      .margin({ top: 16 })

      // 当前状态显示
      Column() {
        Text('调试页面')
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  private openStrategyDialog(): void {
    this.strategyDialogController = new CustomDialogController({
      builder: StarLinkStrategyDialog({}),
      alignment: DialogAlignment.Center,
      backgroundColor: 0xFFFFFFFF
    })
    this.strategyDialogController.open()
  }
}
