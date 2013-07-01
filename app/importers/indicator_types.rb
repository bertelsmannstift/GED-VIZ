module IndicatorTypes

  def self.definitions
    DEFINITIONS
  end

  # Derived IndicatorTypes in mln_persons converted from tsd_persons

  def self.mln_persons_types
    @mln_persons_types ||= definitions.each_with_object({}) do |type_definition, hash|
      source_type = type_definition[:convert_from_tsd]
      next if source_type.blank?

      source = TypeWithUnit.new(
        indicator_type: source_type,
        unit: 'tsd_persons'
      )

      derived = TypeWithUnit.new(
        indicator_type: type_definition[:type],
        unit: type_definition[:unit]
      )

      hash[derived] = source
    end
  end

  # Derived IndicatorTypes that are quotient of two other types

  def self.quotient_types
    @quotient_types ||= definitions.each_with_object({}) do |type_definition, hash|
      formula = type_definition[:formula]
      next if formula.blank?

      parts = formula.split(/[\/\(\)]+/)
      dividend_type, dividend_unit, divisor_type, divisor_unit = parts

      dividend = TypeWithUnit.new(
        indicator_type: dividend_type,
        unit: dividend_unit
      )

      divisor = TypeWithUnit.new(
        indicator_type: divisor_type,
        unit: divisor_unit
      )

      derived = TypeWithUnit.new(
        indicator_type: type_definition[:type],
        unit: type_definition[:unit]
      )

      hash[derived] = [dividend, divisor]
    end
  end

  # Derived IndicatorTypes in (current|real)_dollars_per_capita converted by
  # x(y) / population_src(tsd_persons) * 1000

  def self.per_capita_types
    @per_capita_types ||= Hash.new.tap do |hash|

      # The divisor twu is always population in thousands
      divisor = TypeWithUnit.new(
        indicator_type: 'population_src',
        unit: 'tsd_persons'
      )

      definitions.each do |type_definition|
        per_capita_from = type_definition[:per_capita_from]
        next if per_capita_from.blank?

        source_type, source_unit = per_capita_from.split(/[()]/)

        dividend = TypeWithUnit.new(
          indicator_type: source_type,
          unit: source_unit
        )

        derived = TypeWithUnit.new(
          indicator_type: type_definition[:type],
          unit: type_definition[:unit]
        )

        hash[derived] = [dividend, divisor]
      end
    end
  end

  DEFINITIONS = [
    # prognos_name: Identifier used in the Prognos data CSVs
    # description: Prognos description
    # group: Group name, not present if not in a group
    # type: Type key that is created
    # unit: Unit key
    # prognos_formula: Formula for derived types, using prognos_names
    # formula: Formula for derived types that are quotients of other types
    #          Format: type_key1(unit_key1)/type_key2(unit_key2)'
    # convert_from_tsd: Reference type for derived units in million that
    #                   are converted from thousands on import

    # V
    {
      prognos_name: 'v110',
      description: 'Employment in Tsd. Persons',
      type: 'employment_src',
      unit: 'tsd_persons',
      external: false
    },
    {
      prognos_name: 'v120',
      description: 'Unemployment in Tsd. Persons',
      type: 'unemployment_src',
      unit: 'tsd_persons',
      external: false
    },

    # VR
    {
      prognos_name: 'vr210',
      description: 'Capital Stock, Total Economy in US-$, real (Base Year=2005)',
      group: 'capital',
      type: 'capital_stock_total',
      unit: 'bln_real_dollars',
      position: 3
    },
    {
      prognos_name: 'vr311',
      description: 'Private Consumption in US-$, real (Base Year=2005)',
      group: 'consumption',
      type: 'cons_pvt',
      unit: 'bln_real_dollars',
      position: 1
    },
    {
      prognos_name: 'vr312',
      description: 'Consumption Total Government in US-$, real (Base Year=2005)',
      group: 'consumption',
      type: 'cons_gvt',
      unit: 'bln_real_dollars',
      position: 2
    },
    {
      prognos_name: 'vr300',
      description: 'Gross Domestic Product in US-$, real (Base Year=2005)',
      type: 'gdp',
      unit: 'bln_real_dollars',
      position: 0
    },
    {
      prognos_name: 'vr320',
      description: 'Gross Fixed Capital Formation in US-$, real (Base Year=2005)',
      group: 'capital',
      type: 'cap_form',
      unit: 'bln_real_dollars',
      position: 3
    },
    {
      prognos_name: 'vr340',
      description: 'Total Export in US-$, real (Base Year=2005)',
      group: 'trade',
      type: 'export',
      unit: 'bln_real_dollars',
      position: 5
    },
    {
      prognos_name: 'vr350',
      description: 'Total Import in US-$, real (Base Year=2005)',
      group: 'trade',
      type: 'import',
      unit: 'bln_real_dollars',
      position: 4
    },

    # VN
    {
      prognos_name: 'vn300',
      description: 'Gross Domestic Product in US-$, current prices',
      type: 'gdp_src',
      unit: 'bln_current_dollars',
      external: false
    },
    {
      prognos_name: 'vn520',
      description: 'Current Account in US-$, current prices',
      type: 'account_src',
      unit: 'bln_current_dollars',
      external: false
    },
    {
      prognos_name: 'vn620',
      description: 'Budget Balance, Total Government in US-$, current prices',
      type: 'budget_balance_src',
      unit: 'bln_current_dollars',
      external: false
    },
    {
      prognos_name: 'vn630',
      description: 'Gross Debt, Total Government in US-$, current prices',
      type: 'gross_debt_gvt_src',
      unit: 'bln_current_dollars',
      external: false
    },

    # VP
    {
      prognos_name: 'vp311d',
      description: 'Inflation Rate (Private Consumption) in Percent',
      type: 'inflation',
      unit: 'percent',
      position: 9
    },

    # LAB
    {
      prognos_name: 'lab0099',
      description: 'Labor Force in Tsd. Persons',
      type: 'labor_force_src',
      unit: 'tsd_persons',
      external: false
    },

    # POP
    {
      prognos_name: 'pop0099',
      description: 'Total Population in Tsd. Persons',
      type: 'population_src',
      unit: 'tsd_persons',
      external: false
    },
    {
      prognos_name: 'pop1564',
      description: 'Population 15-64 Years in Tsd. Persons',
      type: 'pop1564',
      unit: 'tsd_persons',
      external: false
    },
    {
      prognos_name: 'pop64plus',
      description: 'Population older 64 years in Tsd. Persons',
      type: 'pop64plus',
      unit: 'tsd_persons',
      external: false
    },

    # XN
    {
      prognos_name: 'xn10',
      description: 'Short-Term Interest Rate in Percent',
      type: 'stir',
      unit: 'percent',
      position: 10
    },

    # Derived indicator types
    # -----------------------

    # Thousand persons to million persons conversion
    # ----------------------------------------------

    {
      description: 'Total Population in Mln. Persons',
      type: 'population',
      unit: 'mln_persons',
      position: 14,
      convert_from_tsd: 'population_src'
    },

    {
      description: 'Labor Force in Mln. Persons',
      group: 'labor',
      type: 'labor_force',
      unit: 'mln_persons',
      position: 11,
      convert_from_tsd: 'labor_force_src'
    },

    {
      description: 'Employment in Mln. Persons',
      group: 'labor',
      type: 'employment',
      unit: 'mln_persons',
      position: 12,
      convert_from_tsd: 'employment_src'
    },

    {
      description: 'Unemployment in Mln. Persons',
      group: 'labor',
      type: 'unemployment',
      unit: 'mln_persons',
      position: 13,
      convert_from_tsd: 'unemployment_src'
    },

    # Quotient formulas
    # -----------------

    # LAB
    {
      description: 'Labor force in Percent of Population',
      group: 'labor',
      type: 'labor_force',
      unit: 'percent',
      formula: 'labor_force_src(tsd_persons)/population_src(tsd_persons)',
      position: 11
    },

    # Q
    {
      description: 'Employment Rate in Percent',
      group: 'labor',
      type: 'employment',
      unit: 'percent',
      formula: 'employment_src(tsd_persons)/labor_force_src(tsd_persons)',
      position: 12
    },
    {
      prognos_name: 'q120',
      description: 'Unemployment Rate in Percent',
      group: 'labor',
      type: 'unemployment',
      unit: 'percent',
      prognos_formula: 'q120=v120/lab0099',
      formula: 'unemployment_src(tsd_persons)/labor_force_src(tsd_persons)',
      position: 13
    },
    {
      prognos_name: 'q65ratio',
      description: 'Old Age Dependency Ratio in Percent',
      type: 'oadr',
      unit: 'percent',
      prognos_formula: 'q65ratio=pop64plus/pop1564',
      formula: 'pop64plus(tsd_persons)/pop1564(tsd_persons)',
      position: 15
    },

    # QR
    {
      prognos_name: 'qr311',
      description: 'Share Private Consumption in Percent of GDP',
      group: 'consumption',
      type: 'cons_pvt',
      unit: 'percent_of_gdp',
      prognos_formula: 'qr311=vr311/vr300',
      formula: 'cons_pvt(bln_real_dollars)/gdp(bln_real_dollars)',
      position: 1
    },
    {
      prognos_name: 'qr312',
      description: 'Share Consumption Total Government in Percent of GDP',
      group: 'consumption',
      type: 'cons_gvt',
      unit: 'percent_of_gdp',
      prognos_formula: 'qr312=vr312/vr300',
      formula: 'cons_gvt(bln_real_dollars)/gdp(bln_real_dollars)',
      position: 2
    },
    {
      prognos_name: 'qr320',
      description: 'Share Gross Fixed Capital Formation in Percent of GDP',
      group: 'capital',
      type: 'cap_form',
      unit: 'percent_of_gdp',
      prognos_formula: 'qr320=vr320/vr300',
      formula: 'cap_form(bln_real_dollars)/gdp(bln_real_dollars)',
      position: 3
    },
    {
      prognos_name: 'qr340',
      description: 'Share Total Export in Percent of GDP',
      group: 'trade',
      type: 'export',
      unit: 'percent_of_gdp',
      prognos_formula: 'qr340=vr340/vr300',
      formula: 'export(bln_real_dollars)/gdp(bln_real_dollars)',
      position: 5
    },
    {
      prognos_name: 'qr350',
      description: 'Share Total Import in Percent of GDP',
      group: 'trade',
      type: 'import',
      unit: 'percent_of_gdp',
      prognos_formula: 'qr350=vr350/vr300',
      formula: 'import(bln_real_dollars)/gdp(bln_real_dollars)',
      position: 4
    },

    # QN
    {
      prognos_name: 'qn520',
      description: 'Share Current Account in Percent of GDP',
      type: 'account',
      unit: 'percent_of_gdp',
      prognos_formula: 'qn520=vn520/vn300',
      formula: 'account_src(bln_current_dollars)/gdp_src(bln_current_dollars)',
      position: 6
    },
    {
      prognos_name: 'qn620',
      description: 'Share Budget Balance, Total Government in Percent of GDP',
      group: 'debt_gvt',
      type: 'budget_balance',
      unit: 'percent_of_gdp',
      prognos_formula: 'qn620=vn620/vn300',
      formula: 'budget_balance_src(bln_current_dollars)/gdp_src(bln_current_dollars)',
      position: 8
    },
    {
      prognos_name: 'qn630',
      description: 'Share Gross Debt, Total Government in Percent of GDP',
      group: 'debt_gvt',
      type: 'gross_debt_gvt',
      unit: 'percent_of_gdp',
      prognos_formula: 'qn630=vn630/vn300',
      formula: 'gross_debt_gvt_src(bln_current_dollars)/gdp_src(bln_current_dollars)',
      position: 7
    },

    # Derived per capita types
    # ------------------------

    {
      description: 'GDP in US-$ (real, Base Year=2005) per capita',
      type: 'gdp',
      unit: 'real_dollars_per_capita',
      position: 0,
      per_capita_from: 'gdp(bln_real_dollars)'
    },

    {
      description: 'Private Consumption in US-$ real (Base Year=2005) per capita',
      group: 'consumption',
      type: 'cons_pvt',
      unit: 'real_dollars_per_capita',
      position: 1,
      per_capita_from: 'cons_pvt(bln_real_dollars)'
    },

    {
      description: 'Consumption Total Government in US-$ real (Base Year=2005) per capita',
      group: 'consumption',
      type: 'cons_gvt',
      unit: 'real_dollars_per_capita',
      position: 2,
      per_capita_from: 'cons_gvt(bln_real_dollars)'
    },

    {
      description: 'Capital Stock, Total Economy in US-$ real (Base Year=2005) per capita',
      group: 'capital',
      type: 'capital_stock_total',
      unit: 'real_dollars_per_capita',
      position: 3,
      per_capita_from: 'capital_stock_total(bln_real_dollars)'
    },

    {
      description: 'Gross Fixed Capital Formation in US-$, real (Base Year=2005) per capita',
      group: 'capital',
      type: 'cap_form',
      unit: 'real_dollars_per_capita',
      position: 3,
      per_capita_from: 'cap_form(real_dollars_per_capita)'
    },

    {
      description: 'Total Import in US-$, real (Base Year=2005) per capita',
      group: 'trade',
      type: 'import',
      unit: 'real_dollars_per_capita',
      position: 4,
      per_capita_from: 'cap_form(bln_real_dollars)'
    },

    {
      description: 'Total Export in US-$, real (Base Year=2005) per capita',
      group: 'trade',
      type: 'export',
      unit: 'real_dollars_per_capita',
      position: 5,
      per_capita_from: 'export(bln_real_dollars)'
    }

  ]
end
