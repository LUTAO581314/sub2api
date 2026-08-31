<template>
  <div class="plaza-pricing-table overflow-x-auto" :style="accentStyle">
    <table class="w-full min-w-[560px] table-fixed border-collapse text-sm tabular-nums">
      <colgroup>
        <col class="w-[32%]" />
        <col class="w-[18%]" />
        <col class="w-[18%]" />
        <col class="w-[32%]" />
      </colgroup>
      <thead>
        <tr
          class="text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-dark-400"
        >
          <th
            rowspan="2"
            class="border-r border-gray-100 py-2.5 pl-5 pr-4 text-left align-middle dark:border-dark-700/60"
          >
            {{ t('modelPlaza.table.model') }}
          </th>
          <th colspan="3" class="pz-bg pt-2 text-center">
            <div class="pz-title border-b pb-2 font-semibold">
              {{ priceMode === 'official' ? t('modelPlaza.table.officialPrice') : t('modelPlaza.table.paidPrice') }}
              <span class="pz-unit ml-1 normal-case font-normal">{{ priceUnit }}</span>
            </div>
          </th>
        </tr>
        <tr
          class="border-b border-gray-200 text-left text-[11px] font-medium uppercase leading-4 tracking-wide text-gray-400 dark:border-dark-700 dark:text-dark-500"
        >
          <th class="pz-bg px-3 py-2 font-medium">{{ t('modelPlaza.table.input') }}</th>
          <th class="pz-bg px-3 py-2 font-medium">{{ t('modelPlaza.table.output') }}</th>
          <th class="pz-bg px-3 py-2 font-medium">{{ t('modelPlaza.table.cache') }}</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="m in sortedModels"
          :key="`${m.platform}:${m.name}`"
          class="border-b border-gray-100 transition-colors last:border-b-0 hover:bg-gray-50/70 dark:border-dark-800 dark:hover:bg-dark-800/50"
        >
          <!-- 模型名 + 非 token 计费模式徽章 -->
          <td class="border-r border-gray-100 py-2.5 pl-5 pr-4 align-middle dark:border-dark-700/60">
            <div class="flex flex-wrap items-center gap-1.5">
              <span class="font-medium text-gray-900 dark:text-white">{{ m.name }}</span>
              <span
                v-if="savingsLabel(m)"
                class="rounded-md bg-emerald-50 px-1.5 py-0.5 text-[10px] font-semibold text-emerald-700 dark:bg-emerald-900/25 dark:text-emerald-300"
              >
                {{ savingsLabel(m) }}
              </span>
              <span
                v-if="platform && m.platform !== platform"
                :class="[
                  'inline-flex items-center rounded-md px-1.5 py-0.5 text-[10px] font-medium',
                  platformBadgeLightClass(m.platform)
                ]"
              >
                {{ platformLabel(m.platform) }}
              </span>
              <span
                v-if="billingMode(m) !== BILLING_MODE_TOKEN"
                class="rounded-md bg-gray-100 px-1.5 py-0.5 text-[10px] font-medium text-gray-500 dark:bg-dark-700/70 dark:text-dark-300"
              >
                {{ billingModeLabel(m) }}
              </span>
            </div>
            <p
              v-if="m.capabilities?.length"
              class="mt-1.5 text-xs leading-5 text-gray-500 dark:text-dark-400"
            >
              {{ (m.capabilities ?? []).join('；') }}
            </p>
          </td>

          <!-- token 计费:输入 / 输出(阶梯内联)/ 缓存(写/读) -->
          <template v-if="billingMode(m) === BILLING_MODE_TOKEN">
            <td class="pz-cell px-3 py-2.5 align-middle font-mono font-semibold text-gray-900 dark:text-gray-50">
              <template v-if="tokenIntervals(m).length">
                <div
                  v-for="(iv, idx) in tokenIntervals(m)"
                  :key="idx"
                  class="whitespace-nowrap text-xs leading-5"
                >
                  <span class="mr-1 font-sans font-normal text-gray-400 dark:text-dark-500">{{ tierLabel(iv) }}</span>
                  {{ paidPerMillion(m, iv.input_price) }}
                </div>
              </template>
              <template v-else>{{ paidPerMillion(m, displayPrice(m, 'input_price')) }}</template>
            </td>
            <td class="pz-cell px-3 py-2.5 align-middle font-mono font-semibold text-gray-900 dark:text-gray-50">
              <template v-if="tokenIntervals(m).length">
                <div
                  v-for="(iv, idx) in tokenIntervals(m)"
                  :key="idx"
                  class="whitespace-nowrap text-xs leading-5"
                >
                  <span class="mr-1 font-sans font-normal text-gray-400 dark:text-dark-500">{{ tierLabel(iv) }}</span>
                  {{ paidPerMillion(m, iv.output_price) }}
                </div>
              </template>
              <template v-else>{{ paidPerMillion(m, displayPrice(m, 'output_price')) }}</template>
            </td>
            <td class="pz-cell px-3 py-2.5 align-middle">
              <div
                v-if="hasCachePricing(m)"
                class="space-y-0.5 font-mono text-xs text-gray-800 dark:text-gray-200"
              >
                <div v-if="hasBothCachePrices(m)">
                  <span class="mr-1 font-sans font-normal text-gray-400 dark:text-dark-500">{{ t('modelPlaza.table.cacheWrite') }}</span>
                  {{ paidPerMillion(m, displayPrice(m, 'cache_write_price')) }}
                </div>
                <div v-if="hasBothCachePrices(m)">
                  <span class="mr-1 font-sans font-normal text-gray-400 dark:text-dark-500">{{ t('modelPlaza.table.cacheRead') }}</span>
                  {{ paidPerMillion(m, displayPrice(m, 'cache_read_price')) }}
                </div>
                <div v-else>{{ paidPerMillion(m, singleCachePrice(m)) }}</div>
              </div>
              <span v-else class="text-gray-400 dark:text-dark-500">-</span>
            </td>
          </template>

          <!-- 按次 / 按图片计费:实付区整体合并,阶梯芯片或单一按次价 -->
          <template v-else>
            <td colspan="3" class="pz-cell px-3 py-2.5 align-middle">
              <div
                v-if="mediaIntervals(m).length"
                class="flex flex-wrap items-center gap-1.5"
              >
                <span
                  v-for="(iv, idx) in mediaIntervals(m)"
                  :key="idx"
                  class="inline-flex items-center gap-1 rounded-md bg-gray-100 px-2 py-0.5 font-mono text-xs text-gray-800 dark:bg-dark-700/60 dark:text-gray-200"
                >
                  <span class="font-sans text-gray-400 dark:text-dark-500">{{ tierLabel(iv) }}</span>
                  {{ paidMediaPrice(m, iv)
                  }}<span class="font-sans text-gray-400 dark:text-dark-500">{{ perUnitSuffix(m, iv) }}</span>
                </span>
              </div>
              <template v-else-if="m.pricing?.per_request_price != null">
                <span class="font-mono font-semibold text-gray-900 dark:text-gray-50">
                  {{ paidRequestPrice(m, m.pricing.per_request_price) }}
                </span>
                <span class="ml-1 text-xs text-gray-400 dark:text-dark-500">{{ perUnitSuffix(m) }}</span>
              </template>
              <span v-else class="text-gray-400 dark:text-dark-500">-</span>
            </td>
          </template>

        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { formatScaled } from '@/utils/pricing'
import { platformAccentColor, platformBadgeLightClass, platformLabel } from '@/utils/platformColors'
import {
  BILLING_MODE_TOKEN,
  BILLING_MODE_IMAGE,
  BILLING_MODE_VIDEO,
  type BillingMode
} from '@/constants/channel'
import type { PlazaModel } from '@/api/modelPlaza'
import type { UserPricingInterval } from '@/api/channels'

const props = defineProps<{
  models: PlazaModel[]
  /** 分组平台;实付分区底色随平台着色,未知平台回退品牌青。 */
  platform?: string
  priceMode?: 'retail' | 'official'
}>()

const { t } = useI18n()

/** 实付分区只从平台拿一个主色,浅底/标题/下划线全部由 scoped CSS 用 color-mix 派生。 */
const accentStyle = computed(() => ({ '--plaza-accent': platformAccentColor(props.platform ?? '') }))

const PER_MILLION = 1_000_000
const priceMode = computed(() => props.priceMode ?? 'retail')
const priceUnit = computed(() => {
  if (priceMode.value === 'official') {
    return ' / 1M token'
  }
  return t('modelPlaza.table.unitPerMillion')
})

/**
 * 展示顺序:
 * 1. token 计费的排在前,按图/按次计费的沉到末尾——不同计费单位混排无意义;
 * 2. 组内按对外输出价从高到低,无价格的排最后;
 * 3. 同价按名称降序(新版本号在前,如 gpt-5.6 先于 gpt-5.5)。
 */
const sortedModels = computed(() => {
  return [...props.models].sort((a, b) => {
    const ta = billingMode(a) === BILLING_MODE_TOKEN
    const tb = billingMode(b) === BILLING_MODE_TOKEN
    if (ta !== tb) return ta ? -1 : 1
    const pa = a.pricing?.output_price ?? null
    const pb = b.pricing?.output_price ?? null
    if (pa != null && pb != null && pa !== pb) return pb - pa
    if (pa != null && pb == null) return -1
    if (pa == null && pb != null) return 1
    return b.name.localeCompare(a.name)
  })
})

function billingMode(m: PlazaModel): BillingMode {
  return (m.pricing?.billing_mode || BILLING_MODE_TOKEN) as BillingMode
}

function billingModeLabel(m: PlazaModel): string {
  if (billingMode(m) === BILLING_MODE_IMAGE) return t('modelPlaza.table.perImage')
  if (billingMode(m) === BILLING_MODE_VIDEO) {
    const intervals = mediaIntervals(m)
    const hasPerSecond = intervals.some((iv) => iv.per_second_price != null)
    const hasPerRequest = intervals.some((iv) => iv.per_request_price != null)
    if (hasPerSecond && hasPerRequest) {
      return `${t('modelPlaza.table.perSecond')} / ${t('modelPlaza.table.perRequest')}`
    }
    if (hasPerSecond) return t('modelPlaza.table.perSecond')
  }
  return t('modelPlaza.table.perRequest')
}

/** 价格统一保底 2 位小数,更长的有效小数原样保留。 */
const MIN_DECIMALS = 2

/** 服务端已按实际计费口径计算最终零售价，按 $/1M token 展示。 */
function paidPerMillion(m: PlazaModel, value: number | null | undefined): string {
  if (value == null) return '-'
  return currencyPrefix(m) + formatScaled(value, PER_MILLION, MIN_DECIMALS).replace(/^\$/, '')
}

function currencyPrefix(m: PlazaModel): string {
  return priceMode.value === 'official' && m.official_pricing?.currency === 'CNY' ? '¥' : '$'
}

function showingOfficial(m: PlazaModel): boolean {
  const p = m.official_pricing
  return priceMode.value === 'official' && p != null &&
    [p.input_price, p.output_price, p.cache_write_price, p.cache_read_price].some((v) => v != null)
}

function displayPrice(m: PlazaModel, field: 'input_price' | 'output_price' | 'cache_write_price' | 'cache_read_price'): number | null | undefined {
  if (showingOfficial(m)) return m.official_pricing?.[field]
  return m.pricing?.[field]
}

function savingsLabel(m: PlazaModel): string {
  const official = m.official_pricing
  const retail = m.pricing
  if (!official || !retail || billingMode(m) !== BILLING_MODE_TOKEN) return ''
  // Official references are mixed-currency (domestic CNY and international USD).
  // Comparing their raw numeric values produces a fake discount.
  if (official.currency !== 'USD') return ''
  const pairs: Array<[number | null, number | null]> = [
    [official.input_price, retail.input_price],
    [official.output_price, retail.output_price],
    [official.cache_write_price, retail.cache_write_price],
    [official.cache_read_price, retail.cache_read_price]
  ]
  const rates = pairs
    .filter(([reference, current]) => reference != null && current != null && reference > 0)
    .map(([reference, current]) => ((reference! - current!) / reference!) * 100)
  if (!rates.length) return ''
  const average = rates.reduce((sum, rate) => sum + rate, 0) / rates.length
  if (average <= 0) return t('modelPlaza.table.aboveOfficial', { percent: Math.abs(average).toFixed(1) })
  return t('modelPlaza.table.saving', { percent: average.toFixed(1) })
}

/** 按次 / 按图片单价由服务端预先算好，不换算 1M。 */
function paidRequestPrice(_m: PlazaModel, value: number | null | undefined): string {
  if (value == null) return '-'
  return formatScaled(value, 1, MIN_DECIMALS)
}

/** 非 token 计费的单位后缀:按图片 → “/ 张”,按次 → “/ 次”。 */
function perUnitSuffix(m: PlazaModel, interval?: UserPricingInterval): string {
  return billingMode(m) === BILLING_MODE_IMAGE
    ? t('modelPlaza.table.perUnitImage')
    : billingMode(m) === BILLING_MODE_VIDEO && interval?.per_second_price != null
      ? t('modelPlaza.table.perUnitSecond')
    : t('modelPlaza.table.perUnitRequest')
}

function hasCachePricing(m: PlazaModel): boolean {
  return displayPrice(m, 'cache_write_price') != null || displayPrice(m, 'cache_read_price') != null
}

function hasBothCachePrices(m: PlazaModel): boolean {
  return displayPrice(m, 'cache_write_price') != null && displayPrice(m, 'cache_read_price') != null
}

function singleCachePrice(m: PlazaModel): number | null | undefined {
  return displayPrice(m, 'cache_read_price') ?? displayPrice(m, 'cache_write_price')
}

/** token 模式的阶梯定价(内联进输入/输出列)。 */
function tokenIntervals(m: PlazaModel): UserPricingInterval[] {
  return showingOfficial(m) ? [] : (m.pricing?.intervals ?? [])
}

/** 非 token 模型的档位价格。视频支持按秒或按次，且不能将两者互相折算。 */
function mediaIntervals(m: PlazaModel): UserPricingInterval[] {
  return (m.pricing?.intervals ?? []).filter(
    (iv) => iv.per_request_price != null || iv.per_second_price != null
  )
}

function paidMediaPrice(m: PlazaModel, interval: UserPricingInterval): string {
  const price = interval.per_second_price ?? interval.per_request_price
  return paidRequestPrice(m, price)
}

/** 档位标签:优先管理员配置的 tier_label,否则按 token 区间生成(≤200K / >200K / 200K–1M)。 */
function tierLabel(iv: UserPricingInterval): string {
  if (iv.tier_label) return iv.tier_label
  const { min_tokens: min, max_tokens: max } = iv
  if (max == null) return `>${formatTokenCount(min)}`
  if (min === 0) return `≤${formatTokenCount(max)}`
  return `${formatTokenCount(min)}–${formatTokenCount(max)}`
}

function formatTokenCount(n: number): string {
  if (n >= 1_000_000) return `${trimZero(n / 1_000_000)}M`
  if (n >= 1_000) return `${trimZero(n / 1_000)}K`
  return String(n)
}

function trimZero(n: number): string {
  return String(Math.round(n * 100) / 100)
}
</script>

<style scoped>
/* 实付分区配色统一从 --plaza-accent(平台主色)派生,新增平台无需扩展样式 */
.plaza-pricing-table {
  --pz-title: color-mix(in srgb, var(--plaza-accent) 88%, black);
  --pz-bg: color-mix(in srgb, var(--plaza-accent) 7%, transparent);
  --pz-bg-hover: color-mix(in srgb, var(--plaza-accent) 13%, transparent);
}

.dark .plaza-pricing-table {
  --pz-title: color-mix(in srgb, var(--plaza-accent) 70%, white);
  --pz-bg: color-mix(in srgb, var(--plaza-accent) 6%, transparent);
  --pz-bg-hover: color-mix(in srgb, var(--plaza-accent) 10%, transparent);
}

.pz-bg,
.pz-cell {
  background-color: var(--pz-bg);
}

.pz-cell {
  transition: background-color 150ms cubic-bezier(0.4, 0, 0.2, 1);
}

tbody tr:hover .pz-cell {
  background-color: var(--pz-bg-hover);
}

.pz-title {
  /* color-mix 不可用的老浏览器回退为平台原色 */
  color: var(--plaza-accent);
  color: var(--pz-title);
  border-color: color-mix(in srgb, var(--pz-title) 30%, transparent);
}

.pz-unit {
  color: color-mix(in srgb, var(--pz-title) 62%, transparent);
}
</style>
