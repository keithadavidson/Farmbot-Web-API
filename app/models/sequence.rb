class Sequence < ActiveRecord::Base
  COLORS = %w(blue green yellow orange purple pink gray red)
  belongs_to :device
  has_many :regimen_items
  has_many  :sequence_dependencies, dependent: :destroy

  serialize :body, Array
  serialize :args, Hash

  # allowable label colors for the frontend.
  [ :name, :kind ].each { |n| validates n, presence: true }
  validates_inclusion_of :color, in: COLORS
  validates_uniqueness_of :name, scope: :device
  STEPS = [ :var_set, :var_get, :move_absolute, :move_relative, :write_pin,
            :read_pin, :wait, :send_message, :execute, :if_statement]

  Corpus = CeleryScript::Corpus
      .new
      .defineArg(:x,               [Fixnum])
      .defineArg(:y,               [Fixnum])
      .defineArg(:z,               [Fixnum])
      .defineArg(:speed,           [Fixnum])
      .defineArg(:pin_number,      [Fixnum])
      .defineArg(:pin_value,       [Fixnum])
      .defineArg(:pin_mode,        [Fixnum])
      .defineArg(:data_label,      [String])
      .defineArg(:data_value,      [String])
      .defineArg(:data_type,       [String])
      .defineArg(:milliseconds,    [Fixnum])
      .defineArg(:message,         [String])
      .defineArg(:sub_sequence_id, [Fixnum]) do |node|
        missing = !exists?(node.value)
        node.invalidate!("Sequence ##{ node.value } does not exist.") if missing
      end
      .defineArg(:lhs,             [String])
      .defineArg(:op,              [String])
      .defineArg(:rhs,             [Fixnum])
      .defineNode(:var_set,        [:data_label, :data_type])
      .defineNode(:var_get,        [:data_label, :data_type, :data_value],)
      .defineNode(:move_absolute,  [:x, :y, :z, :speed],)
      .defineNode(:move_relative,  [:x, :y, :z, :speed],)
      .defineNode(:write_pin,      [:pin_number, :pin_value, :pin_mode ],)
      .defineNode(:read_pin,       [:pin_number, :data_label, :pin_mode])
      .defineNode(:wait,           [:milliseconds])
      .defineNode(:send_message,   [:message])
      .defineNode(:execute,        [:sub_sequence_id])
      .defineNode(:if_statement,   [:lhs, :op, :rhs, :sub_sequence_id])
      .defineNode(:sequence,       [], STEPS)
    puts "TODO: Write custom validators for constants below: "
    ALLOWED_DATA_TYPES = ["string", "integer"]
    ALLOWED_OPS = ["<", ">", "is", "not"]
    ALLOWED_PIN_MODES = [0, 1]
    ALLOWED_LHS = [ "x", "y", "z", "s", "busy",
                    "param_version", "movement_timeout_x",
                    "movement_timeout_y", "movement_timeout_z",
                    "movement_invert_endpoints_x", "movement_invert_endpoints_y",
                    "movement_invert_endpoints_z", "movement_invert_motor_x",
                    "movement_invert_motor_y", "movement_invert_motor_z",
                    "movement_steps_acc_dec_x", "movement_steps_acc_dec_y",
                    "movement_steps_acc_dec_z", "movement_home_up_x",
                    "movement_home_up_y", "movement_home_up_z", "movement_min_spd_x",
                    "movement_min_spd_y", "movement_min_spd_z", "movement_max_spd_x",
                    "movement_max_spd_y", "movement_max_spd_z", "time", "pin0", "pin1",
                    "pin2", "pin3", "pin4", "pin5", "pin6", "pin7", "pin8", "pin9",
                    "pin10", "pin11", "pin12", "pin13", ]

  # http://stackoverflow.com/a/5127684/1064917
  before_validation :set_defaults

  def set_defaults
    self.color ||= "gray"
    self.kind ||= "sequence"
    self.body ||= []
    self.args ||= {}
  end
end
