# Pеляционная алгебра
## Запрос 1 
**Формулировка на естественном языке:** Найти идентификаторы клиентов (ClientID), у которых есть активный абонемент (Status = 'active').

**Реляционная алгебра:**
π_{ClientID} ( σ_{Status = 'active'} ( Membership ) )

## Запрос 2 
**Формулировка на естественном языке:** Найти имена клиентов и их тип абонемента.

**Реляционная алгебра:**
π_{Client.FirstName, Client.LastName, Membership.Type} 
   (Client ⋈_{Client.ClientID = Membership.ClientID} Membership)
