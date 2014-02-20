module IndicatorTypes

  def self.type_definitions
    TYPE_DEFINITIONS
  end

  def self.unit_definitions
    UNIT_DEFINITIONS
  end

  # Parse 'type_key(unit_key)' to a TypeWithUnit instance
  def self.parse_type_with_unit(string)
    type_key, unit_key = string.split(/[()]/)
    TypeWithUnit.new(
      indicator_type: type_key,
      unit: unit_key
    )
  end

  # Simple derived IndicatorTypes
  # Returns an array with hashes:
  # [ { twu: TypeWithUnit, source: TypeWithUnit, converter: Proc }, … ]

  def self.derived_types
    @derived_types ||= type_definitions.each_with_object([]) do |type_definition, types|
      source = type_definition[:source]
      next if source.nil?
      source = parse_type_with_unit(source)

      type_key = type_definition[:type]
      unit_key = type_definition[:unit]
      converter = type_definition[:converter]

      for_all_currencies unit_key do |unit_key|
        twu = TypeWithUnit.new indicator_type: type_key, unit: unit_key

        types << {
          twu: twu,
          source: source,
          converter: converter
        }
      end
    end
  end

  # Derived IndicatorTypes that are quotient of two other types
  # Returns an array with hashes:
  # [ { twu: TypeWithUnit, dividend: TypeWithUnit, divisor: TypeWithUnit, converter: Proc }, … ]

  def self.quotient_types
    @quotient_types ||= type_definitions.each_with_object([]) do |type_definition, types|
      formula = type_definition[:formula]
      next if formula.blank?

      type_key = type_definition[:type]
      unit_key = type_definition[:unit]
      converter = type_definition[:converter]

      for_all_currencies unit_key do |unit_key|
        twu = TypeWithUnit.new(
          indicator_type: type_key,
          unit: unit_key
        )

        parts = formula.split(/[\/()]+/)
        dividend_type, dividend_unit, divisor_type, divisor_unit = parts

        dividend = TypeWithUnit.new(
          indicator_type: dividend_type,
          unit: dividend_unit
        )

        divisor = TypeWithUnit.new(
          indicator_type: divisor_type,
          unit: divisor_unit
        )

        types << {
          twu: twu,
          dividend: dividend,
          divisor: divisor,
          converter: converter
        }
      end
    end
  end

  # Types with values that are addable when calculating
  # the sum for a country group
  # Returns an array of TypeWithUnit objects: [ TypeWithUnit, … ]

  def self.addable_types
    @addable_types ||= type_definitions.each_with_object([]) do |type_definition, types|
      type_key = type_definition[:type]
      unit_key = type_definition[:unit]
      formula = type_definition[:formula]

      addable =
        # Total import/export are not addable because
        # they include the trade between the countries
        type_key != 'import' &&
        type_key != 'export' &&
        # Percent values are only addable if they are quotient values
        (unit_key != 'percent' || formula.present?)

      next unless addable

      for_all_currencies unit_key do |unit_key|
        twu = TypeWithUnit.new indicator_type: type_key, unit: unit_key
        types << twu
      end
    end
  end

  # Call a block for all currencies

  def self.for_all_currencies(unit, &proc)
    proc.call unit
    CurrencyConverter.other_unit(unit, &proc)
  end

  # For a given Prognos name, return an array with the corresponding type and unit keys

  def self.prognos_key_to_type_and_unit
    @prognos_key_to_type_and_unit ||= Hash.new.tap do |hash|
      type_definitions.each do |type_definition|
        prognos_name = type_definition[:prognos_name]
        next if prognos_name.nil?
        type_key = type_definition[:type]
        unit_key = type_definition[:unit]
        hash[prognos_name] = [type_key, unit_key]
      end
    end
  end

  # Converters
  # ----------

  CONVERT_FROM_TSD = lambda { |value|
    value / 1000.0
  }

  CURRENCIES_IN_BILLION =
    %w(bln_real_dollars bln_current_dollars bln_real_euros bln_current_euros)

  CONVERT_PER_CAPITA = lambda { |dividend, divisor, dividend_twu, divisor_twu|

    # Convert billion dollars/euros to dollars/euros
    if CURRENCIES_IN_BILLION.include?(dividend_twu.unit.key)
      dividend = dividend * 1000000000
    end

    # Convert thousand persons to persons
    if divisor_twu.unit.key == 'tsd_persons'
      divisor = divisor * 1000
    end

    [dividend, divisor]
  }

  CONVERT_PERCENT = lambda { |dividend, divisor, dividend_twu, divisor_twu|
    dividend = dividend * 100
    [dividend, divisor]
  }

  # Type definitions
  # ----------------

  TYPE_DEFINITIONS = [
    # prognos_name: Identifier used in the Prognos data CSVs
    # description: Prognos description
    # group: Group name, not present if not in a group
    # type: Type key that is created
    # unit: Unit key
    # prognos_formula: Formula for derived types, using prognos_names
    # source: Reference type for derived units
    #         Format: type_key(unit_key)
    # formula: Formula for derived types that are quotients of other types
    #          Format: type_key1(unit_key1)/type_key2(unit_key2)'
    # converter: Proc
    #            Value conversion for derived types
    # external: Boolean. Whether to show in the UI
    # position: Integer. Position in the UI
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

    # Derived person types
    # --------------------

    {
      description: 'Total Population in Mln. Persons',
      type: 'population',
      unit: 'mln_persons',
      source: 'population_src(tsd_persons)',
      converter: CONVERT_FROM_TSD,
      position: 14
    },

    {
      description: 'Labor Force in Mln. Persons',
      group: 'labor',
      type: 'labor_force',
      unit: 'mln_persons',
      source: 'labor_force_src(tsd_persons)',
      converter: CONVERT_FROM_TSD,
      position: 11
    },

    {
      description: 'Employment in Mln. Persons',
      group: 'labor',
      type: 'employment',
      unit: 'mln_persons',
      source: 'employment_src(tsd_persons)',
      converter: CONVERT_FROM_TSD,
      position: 12
    },

    {
      description: 'Unemployment in Mln. Persons',
      group: 'labor',
      type: 'unemployment',
      unit: 'mln_persons',
      source: 'unemployment_src(tsd_persons)',
      converter: CONVERT_FROM_TSD,
      position: 13
    },

    # Derived quotient types
    # ----------------------

    # LAB
    {
      description: 'Labor force in Percent of Population',
      group: 'labor',
      type: 'labor_force',
      unit: 'percent_of_population',
      formula: 'labor_force_src(tsd_persons)/population_src(tsd_persons)',
      converter: CONVERT_PERCENT,
      position: 11
    },

    # Q
    {
      description: 'Employment Rate in Percent',
      group: 'labor',
      type: 'employment',
      unit: 'percent_of_labor_force',
      formula: 'employment_src(tsd_persons)/labor_force_src(tsd_persons)',
      converter: CONVERT_PERCENT,
      position: 12
    },
    {
      prognos_name: 'q120',
      description: 'Unemployment Rate in Percent',
      group: 'labor',
      type: 'unemployment',
      unit: 'percent_of_labor_force',
      prognos_formula: 'q120=v120/lab0099',
      formula: 'unemployment_src(tsd_persons)/labor_force_src(tsd_persons)',
      converter: CONVERT_PERCENT,
      position: 13
    },
    {
      prognos_name: 'q65ratio',
      description: 'Old Age Dependency Ratio in Percent',
      type: 'oadr',
      unit: 'percent_of_population',
      prognos_formula: 'q65ratio=pop64plus/pop1564',
      formula: 'pop64plus(tsd_persons)/pop1564(tsd_persons)',
      converter: CONVERT_PERCENT,
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
      converter: CONVERT_PERCENT,
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
      converter: CONVERT_PERCENT,
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
      converter: CONVERT_PERCENT,
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
      converter: CONVERT_PERCENT,
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
      converter: CONVERT_PERCENT,
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
      converter: CONVERT_PERCENT,
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
      converter: CONVERT_PERCENT,
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
      converter: CONVERT_PERCENT,
      position: 7
    },

    # Derived per capita types
    # ------------------------

    {
      description: 'GDP in US-$ (real, Base Year=2005) per capita',
      type: 'gdp',
      unit: 'real_dollars_per_capita',
      formula: 'gdp(bln_real_dollars)/population_src(tsd_persons)',
      converter: CONVERT_PER_CAPITA,
      position: 0
    },

    {
      description: 'Private Consumption in US-$ real (Base Year=2005) per capita',
      group: 'consumption',
      type: 'cons_pvt',
      unit: 'real_dollars_per_capita',
      formula: 'cons_pvt(bln_real_dollars)/population_src(tsd_persons)',
      converter: CONVERT_PER_CAPITA,
      position: 1
    },

    {
      description: 'Consumption Total Government in US-$ real (Base Year=2005) per capita',
      group: 'consumption',
      type: 'cons_gvt',
      unit: 'real_dollars_per_capita',
      formula: 'cons_gvt(bln_real_dollars)/population_src(tsd_persons)',
      converter: CONVERT_PER_CAPITA,
      position: 2
    },

    {
      description: 'Capital Stock, Total Economy in US-$ real (Base Year=2005) per capita',
      group: 'capital',
      type: 'capital_stock_total',
      unit: 'real_dollars_per_capita',
      formula: 'capital_stock_total(bln_real_dollars)/population_src(tsd_persons)',
      converter: CONVERT_PER_CAPITA,
      position: 3
    },

    {
      description: 'Gross Fixed Capital Formation in US-$, real (Base Year=2005) per capita',
      group: 'capital',
      type: 'cap_form',
      unit: 'real_dollars_per_capita',
      formula: 'cap_form(bln_real_dollars)/population_src(tsd_persons)',
      converter: CONVERT_PER_CAPITA,
      position: 3
    },

    {
      description: 'Total Import in US-$, real (Base Year=2005) per capita',
      group: 'trade',
      type: 'import',
      unit: 'real_dollars_per_capita',
      formula: 'import(bln_real_dollars)/population_src(tsd_persons)',
      converter: CONVERT_PER_CAPITA,
      position: 4
    },

    {
      description: 'Total Export in US-$, real (Base Year=2005) per capita',
      group: 'trade',
      type: 'export',
      unit: 'real_dollars_per_capita',
      formula: 'export(bln_real_dollars)/population_src(tsd_persons)',
      converter: CONVERT_PER_CAPITA,
      position: 5
    }

  ]
  private_constant :TYPE_DEFINITIONS

  UNIT_DEFINITIONS = ActiveSupport::HashWithIndifferentAccess.new({

    # US Dollar
    bln_current_dollars: {
      representation: Unit::ABSOLUTE,
      position: 1
    },
    bln_real_dollars: {
      representation: Unit::ABSOLUTE,
      position: 1
    },
    real_dollars_per_capita: {
      representation: Unit::ABSOLUTE,
      position: 2
    },

    # Euro
    bln_current_euros: {
      representation: Unit::ABSOLUTE,
      position: 1
    },
    bln_real_euros: {
      representation: Unit::ABSOLUTE,
      position: 1
    },
    real_euros_per_capita: {
      representation: Unit::ABSOLUTE,
      position: 2
    },

    # Persons
    persons: {
      representation: Unit::ABSOLUTE,
      position: 1
    },
    tsd_persons: {
      representation: Unit::ABSOLUTE,
      position: 1
    },
    mln_persons: {
      representation: Unit::ABSOLUTE,
      position: 1
    },

    # Percent
    percent: {
      representation: Unit::PROPORTIONAL,
      position: 0
    },
    percent_of_gdp: {
      representation: Unit::PROPORTIONAL,
      position: 0
    },
    percent_of_labor_force: {
      representation: Unit::PROPORTIONAL,
      position: 0
    },
    percent_of_population: {
      representation: Unit::PROPORTIONAL,
      position: 0
    },
  })
  private_constant :UNIT_DEFINITIONS

end
