connection: "azuresqlbi"

# include all the views
include: "/views/**/*.view"

datagroup: maquila_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: maquila_default_datagroup

explore: catalogo_cuentas  {
  join: movimientos {
    type: left_outer
    sql_on: ${catalogo_cuentas.cuenta} = ${movimientos.Cuenta} ;;
    relationship: many_to_many
  }

  #join: clientes_broxel {
#    type: left_outer
 #   sql_on: ${catalogo_cuentas.cliente} = ${clientes_broxel.clave_cliente} ;;
#    relationship: many_to_one
 # }
 # join: maquila {
#    type: left_outer
 #   sql_on: ${catalogo_cuentas.cuenta} = ${maquila.num_cuenta} ;;
#    relationship: many_to_one
 # }
#  join: catalogo_clasificacion_clientes {
#    type: left_outer
#    sql_on: ${clientes_broxel.clasificacion_ctes_broxel} = ${catalogo_clasificacion_clientes.codigo} ;;
#    relationship: many_to_many
#  }
#  sql_always_where: ${ind_movimientos.fclear_date} >= EOMONTH(DATEADD(MONTH, -1, GETDATE()))  ;;
  #where: ${fecha} >= date_trunc('month', CURRENT_DATE - INTERVAL '1' MONTH) AND ${fecha} < date_trunc('month', CURRENT_DATE)
}
