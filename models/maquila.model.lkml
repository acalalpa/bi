connection: "azuresqlbi"

# include all the views
include: "/views/**/*.view"

datagroup: maquila_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: maquila_default_datagroup

explore: maquila {
  join: historico_movimientos {
    type: left_outer
    sql_on: ${maquila.num_cuenta} = ${historico_movimientos.cuenta} ;;
 relationship: many_to_many}
 join: cc_movimiento_enc {
    type: left_outer
    sql_on: ${maquila.num_cuenta} = ${cc_movimiento_enc.num_cuenta} ;;
    relationship: many_to_many}
  join: ind_movimientos {
    type: left_outer
    sql_on: ${maquila.num_cuenta} = ${ind_movimientos.nro_ruc} ;;
    relationship: many_to_many}
}
