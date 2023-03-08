connection: "azuresqlbi"

# include all the views
include: "/views/**/*.view"

datagroup: maquila_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: maquila_default_datagroup

explore: ind_movimientos  {
  join: maquila {
    type: left_outer
    sql_on: ${ind_movimientos.nro_ruc} = ${maquila.num_cuenta} ;;
    relationship: many_to_one

  }
  join: catalogo_cuentas {
    type: left_outer
    sql_on: ${ind_movimientos.nro_ruc} = ${catalogo_cuentas.cuenta} ;;
    relationship: many_to_one
  }
  join: clientes_broxel {
    type: left_outer
    sql_on: ${catalogo_cuentas.cliente} = ${clientes_broxel.clave_cliente} ;;
    relationship: many_to_many
  }
  join: catalogo_clasificacion_clientes {
    type: left_outer
    sql_on: ${clientes_broxel.clasificacion_ctes_broxel} = ${catalogo_clasificacion_clientes.codigo} ;;
    relationship: many_to_many
  }
  sql_always_where: ${fclear_date} >= date_trunc('month', NOW() - INTERVAL '1' MONTH) AND ${fclear_date} < date_trunc('month', CURRENT_DATE)  ;;
  #where: ${fecha} >= date_trunc('month', CURRENT_DATE - INTERVAL '1' MONTH) AND ${fecha} < date_trunc('month', CURRENT_DATE)
}
