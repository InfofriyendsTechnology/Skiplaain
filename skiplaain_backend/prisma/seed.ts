import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Clear existing data
  await prisma.partner.deleteMany({});

  // Create test partners with complete salon data
  const partners = await Promise.all([
    prisma.partner.create({
      data: {
        phone: '+919876543210',
        ownerName: 'Yash Patel',
        salonName: 'Yash Styles Salon',
        address: 'VIP Road, Vesu',
        city: 'Surat',
        pincode: '395007',
        category: 'Unisex',
        status: 'active',
        latitude: 21.1702,
        longitude: 72.8311,
        rating: 4.8,
      },
    }),
    prisma.partner.create({
      data: {
        phone: '+919876543211',
        ownerName: 'Raj Shah',
        salonName: 'Elite Hair Studio',
        address: 'Adajan Patiya, Adajan',
        city: 'Surat',
        pincode: '395009',
        category: 'Men',
        status: 'active',
        latitude: 21.1959,
        longitude: 72.7933,
        rating: 4.5,
      },
    }),
    prisma.partner.create({
      data: {
        phone: '+919876543212',
        ownerName: 'Priya Desai',
        salonName: 'Glamour Lounge',
        businessName: 'Glamour Lounge',
        address: 'Pal, Pal Adajan Road',
        city: 'Surat',
        pincode: '395009',
        category: 'Women',
        status: 'active',
        latitude: 21.2156,
        longitude: 72.8397,
        rating: 4.9,
      },
    }),
    prisma.partner.create({
      data: {
        phone: '+919876543213',
        ownerName: 'Amit Kumar',
        salonName: 'Style Hub Barbers',
        businessName: 'Style Hub Barbers',
        address: 'Citylight Road, Surat',
        city: 'Surat',
        pincode: '395007',
        category: 'Men',
        status: 'active',
        latitude: 21.1864,
        longitude: 72.8081,
        rating: 4.6,
      },
    }),
    prisma.partner.create({
      data: {
        phone: '+919876543214',
        ownerName: 'Neha Sharma',
        salonName: 'Beauty Paradise',
        businessName: 'Beauty Paradise',
        address: 'Althan, LP Savani Road',
        city: 'Surat',
        pincode: '395017',
        category: 'Unisex',
        status: 'active',
        latitude: 21.1591,
        longitude: 72.7865,
        rating: 4.7,
      },
    }),
  ]);

  console.log(`✅ Created ${partners.length} test partners`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
